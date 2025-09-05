// Fetch current AWS account ID
data "aws_caller_identity" "current" {}

// IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec" {
  name               = "${terraform.workspace}-${var.stack_id}-lambda-exec-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

// Policy to allow DynamoDB read on user tree table
data "aws_iam_policy_document" "dynamo_read" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.table_name}"]
  }
}

resource "aws_iam_role_policy" "lambda_dynamo" {
  name   = "${terraform.workspace}-${var.stack_id}-lambda-dynamo-policy"
  role   = aws_iam_role.lambda_exec.name
  policy = data.aws_iam_policy_document.dynamo_read.json
}

// Package and deploy user tree Lambda function assets
resource "archive_file" "user_tree_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/user_tree"
  output_path = "${path.module}/user_tree.zip"
}

// Lambda function for user tree
resource "aws_lambda_function" "user_tree" {
  filename      = archive_file.user_tree_zip.output_path
  # Force update when ZIP content changes
  source_code_hash = filebase64sha256(archive_file.user_tree_zip.output_path)
  function_name = "${terraform.workspace}-${var.stack_id}-user-tree"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  role          = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
  depends_on = [aws_iam_role_policy.lambda_dynamo, archive_file.user_tree_zip]
}
// Attach basic execution policy so Lambda can emit logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// HTTP API Gateway
resource "aws_apigatewayv2_api" "http" {
  name          = "${terraform.workspace}-${var.stack_id}-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 3600
  }
}

// Integration with Lambda
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.user_tree.invoke_arn
  payload_format_version = "2.0"
}

// Define GET /tree route
resource "aws_apigatewayv2_route" "get_tree" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /tree"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

// Deploy stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

// Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGwInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_tree.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}