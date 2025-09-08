// Fetch current AWS account ID
data "aws_caller_identity" "current" {}

// IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec" {
  name               = "${terraform.workspace}-lambda-exec-role"
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
      "dynamodb:Scan",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.table_name}",
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.teams_table_name}"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_dynamo" {
  name   = "${terraform.workspace}-lambda-dynamo-policy"
  role   = aws_iam_role.lambda_exec.name
  policy = data.aws_iam_policy_document.dynamo_read.json
}
// Policy to allow Cognito IDP operations (user lookup, creation, grouping)
data "aws_iam_policy_document" "cognito_access" {
  statement {
    effect = "Allow"
    actions = [
      "cognito-idp:AdminGetUser",
      "cognito-idp:AdminCreateUser",
      "cognito-idp:AdminAddUserToGroup",
      "cognito-idp:AdminDeleteUser"
    ]
    resources = [
      "arn:aws:cognito-idp:${var.aws_region}:${data.aws_caller_identity.current.account_id}:userpool/${var.user_pool_id}"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_cognito" {
  name   = "${terraform.workspace}-lambda-cognito-policy"
  role   = aws_iam_role.lambda_exec.name
  policy = data.aws_iam_policy_document.cognito_access.json
}

// Package and deploy user tree Lambda function assets
resource "archive_file" "user_tree_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/user_tree"
  output_path = "${path.module}/user_tree.zip"
}

// Lambda function for user tree
resource "aws_lambda_function" "user_tree" {
  filename = archive_file.user_tree_zip.output_path
  # Force update when ZIP content changes
  source_code_hash = archive_file.user_tree_zip.output_base64sha256
  function_name    = "${terraform.workspace}-user-tree"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
  depends_on = [aws_iam_role_policy.lambda_dynamo, archive_file.user_tree_zip]
}
// Package and deploy fetch_team Lambda
resource "archive_file" "fetch_team_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/fetch_team"
  output_path = "${path.module}/fetch_team.zip"
}
resource "aws_lambda_function" "fetch_team" {
  filename         = archive_file.fetch_team_zip.output_path
  source_code_hash = archive_file.fetch_team_zip.output_base64sha256
  function_name    = "${terraform.workspace}-fetch-team"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
      TEAMS_TABLE = var.teams_table_name
    }
  }
  depends_on = [archive_file.fetch_team_zip]
}
// Package and deploy fetch_manager Lambda
resource "archive_file" "fetch_manager_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/fetch_manager"
  output_path = "${path.module}/fetch_manager.zip"
}
resource "aws_lambda_function" "fetch_manager" {
  filename         = archive_file.fetch_manager_zip.output_path
  source_code_hash = archive_file.fetch_manager_zip.output_base64sha256
  function_name    = "${terraform.workspace}-fetch-manager"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
      USER_TABLE = var.table_name
    }
  }
  depends_on = [archive_file.fetch_manager_zip]
}
// Package and deploy checkavailability Lambda
resource "archive_file" "checkavailability_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/checkavailability"
  output_path = "${path.module}/checkavailability.zip"
}
resource "aws_lambda_function" "checkavailability" {
  filename         = archive_file.checkavailability_zip.output_path
  source_code_hash = archive_file.checkavailability_zip.output_base64sha256
  function_name    = "${terraform.workspace}-checkavailability"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  environment {
    variables = { USER_POOL_ID = var.user_pool_id }
  }
  depends_on = [archive_file.checkavailability_zip, aws_iam_role_policy.lambda_cognito]
}
// Package and deploy cognito_register Lambda
resource "archive_file" "cognito_register_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/cognito_register"
  output_path = "${path.module}/cognito_register.zip"
}
resource "aws_lambda_function" "cognito_register" {
  filename         = archive_file.cognito_register_zip.output_path
  source_code_hash = archive_file.cognito_register_zip.output_base64sha256
  function_name    = "${terraform.workspace}-cognito-register"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  environment {
    variables = { USER_POOL_ID = var.user_pool_id }
  }
  depends_on = [archive_file.cognito_register_zip, aws_iam_role_policy.lambda_cognito]
}
// Package and deploy dynamo_register Lambda
resource "archive_file" "dynamo_register_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/dynamo_register"
  output_path = "${path.module}/dynamo_register.zip"
}
resource "aws_lambda_function" "dynamo_register" {
  filename         = archive_file.dynamo_register_zip.output_path
  source_code_hash = archive_file.dynamo_register_zip.output_base64sha256
  function_name    = "${terraform.workspace}-dynamo-register"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
      TABLE_NAME  = var.table_name
      TEAMS_TABLE = var.teams_table_name
    }
  }
  depends_on = [archive_file.dynamo_register_zip]
}
// Package and deploy manage_team Lambda
resource "archive_file" "manage_team_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/manage_team"
  output_path = "${path.module}/manage_team.zip"
}
resource "aws_lambda_function" "manage_team" {
  filename         = archive_file.manage_team_zip.output_path
  source_code_hash = archive_file.manage_team_zip.output_base64sha256
  function_name    = "${terraform.workspace}-manage-team"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  environment {
    variables = { TEAMS_TABLE = var.teams_table_name }
  }
  depends_on = [archive_file.manage_team_zip]
}
// Package and deploy delete_user Lambda
resource "archive_file" "delete_user_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/delete_user"
  output_path = "${path.module}/delete_user.zip"
}
resource "aws_lambda_function" "delete_user" {
  filename         = archive_file.delete_user_zip.output_path
  source_code_hash = archive_file.delete_user_zip.output_base64sha256
  function_name    = "${terraform.workspace}-delete-user"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
      USER_POOL_ID = var.user_pool_id
      TABLE_NAME   = var.table_name
    }
  }
  depends_on = [archive_file.delete_user_zip]
}
// Package and deploy switch_manager Lambda
resource "archive_file" "switch_manager_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/switch_manager"
  output_path = "${path.module}/switch_manager.zip"
}
resource "aws_lambda_function" "switch_manager" {
  filename         = archive_file.switch_manager_zip.output_path
  source_code_hash = archive_file.switch_manager_zip.output_base64sha256
  function_name    = "${terraform.workspace}-switch-manager"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
  depends_on = [archive_file.switch_manager_zip]
}
// Attach basic execution policy so Lambda can emit logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// HTTP API Gateway
resource "aws_apigatewayv2_api" "http" {
  name          = "${terraform.workspace}-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS", "POST", "DELETE"]
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
// Integration for fetch_team
resource "aws_apigatewayv2_integration" "fetch_team" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.fetch_team.invoke_arn
  payload_format_version = "2.0"
}
// Integration for fetch_manager
resource "aws_apigatewayv2_integration" "fetch_manager" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.fetch_manager.invoke_arn
  payload_format_version = "2.0"
}
// Integration for checkavailability
resource "aws_apigatewayv2_integration" "checkavailability" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.checkavailability.invoke_arn
  payload_format_version = "2.0"
}
// Integration for cognito_register
resource "aws_apigatewayv2_integration" "cognito_register" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.cognito_register.invoke_arn
  payload_format_version = "2.0"
}
// Integration for dynamo_register
resource "aws_apigatewayv2_integration" "dynamo_register" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.dynamo_register.invoke_arn
  payload_format_version = "2.0"
}
// Integration for switch_manager
resource "aws_apigatewayv2_integration" "switch_manager" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.switch_manager.invoke_arn
  payload_format_version = "2.0"
}

// Define GET /tree route
resource "aws_apigatewayv2_route" "get_tree" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /tree"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}
// Route for checkavailability
resource "aws_apigatewayv2_route" "post_checkavailability" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /checkavailability"
  target    = "integrations/${aws_apigatewayv2_integration.checkavailability.id}"
}
// Route for cognito_register
resource "aws_apigatewayv2_route" "post_cognito_register" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /cognito_register"
  target    = "integrations/${aws_apigatewayv2_integration.cognito_register.id}"
}
// Route for dynamo_register
resource "aws_apigatewayv2_route" "post_dynamo_register" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /dynamo_register"
  target    = "integrations/${aws_apigatewayv2_integration.dynamo_register.id}"
}
// Route for fetch_team
resource "aws_apigatewayv2_route" "get_teams" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /teams"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_team.id}"
}
// Route for fetch_manager
resource "aws_apigatewayv2_route" "get_managers" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /managers"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_manager.id}"
}
// Integration for manage_team (create/delete teams)
resource "aws_apigatewayv2_integration" "manage_team" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.manage_team.invoke_arn
  payload_format_version = "2.0"
}
// Route for creating a team
resource "aws_apigatewayv2_route" "post_teams" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /teams"
  target    = "integrations/${aws_apigatewayv2_integration.manage_team.id}"
}
// Route for deleting a team
resource "aws_apigatewayv2_route" "delete_team" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "DELETE /teams/{team_id}"
  target    = "integrations/${aws_apigatewayv2_integration.manage_team.id}"
}
// Integration for delete_user
resource "aws_apigatewayv2_integration" "delete_user" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.delete_user.invoke_arn
  payload_format_version = "2.0"
}
// Route for deleting a user
resource "aws_apigatewayv2_route" "delete_user" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "DELETE /users/{username}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_user.id}"
}
// Route for switch_manager
resource "aws_apigatewayv2_route" "post_switch_manager" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /switch_manager"
  target    = "integrations/${aws_apigatewayv2_integration.switch_manager.id}"
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
// Permissions for fetch_team
resource "aws_lambda_permission" "fetch_team" {
  statement_id  = "AllowFetchTeamInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_team.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
// Permissions for fetch_manager
resource "aws_lambda_permission" "fetch_manager" {
  statement_id  = "AllowFetchManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_manager.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
// Permission for checkavailability
resource "aws_lambda_permission" "checkavailability" {
  statement_id  = "AllowCheckAvailabilityInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.checkavailability.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
// Permission for cognito_register
resource "aws_lambda_permission" "cognito_register" {
  statement_id  = "AllowCognitoRegisterInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_register.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
// Permission for manage_team
resource "aws_lambda_permission" "manage_team" {
  statement_id  = "AllowManageTeamInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.manage_team.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
// Permission for delete_user
resource "aws_lambda_permission" "delete_user" {
  statement_id  = "AllowDeleteUserInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
// Permission for dynamo_register
resource "aws_lambda_permission" "dynamo_register" {
  statement_id  = "AllowDynamoRegisterInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dynamo_register.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
// Permission for switch_manager
resource "aws_lambda_permission" "switch_manager" {
  statement_id  = "AllowSwitchManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.switch_manager.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}