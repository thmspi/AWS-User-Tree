# My Organisation Tree

This project was built to demonstrate my understanding of Terraform and AWS. It provisions a simple web application equiped with an authentification page. The web application allow you administrate (create, delete, switch...) your organisation users using groups, managers, and employees.


## Prerequisites

To run this project, make sure you have:

- **Terraform** installed (v1.x recommended).
- **AWS credentials** available as environment variables:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`

> You can load real values from a `.env` or your CI/CD secrets manager.

## Terraform Cloud / Remote Backend

This project uses **Terraform Cloud** as a remote backend. You can keep that setup or switch to a different backend if you prefer.

### Option A — Terraform Cloud (recommended)

Edit `infra/main.tf` and set your organization and workspace:


```hcl
terraform {

  backend "remote" {
    organization = "YOUR_ORG"
    workspaces {
      name = "YOUR_WORKSPACE"
    }
  }
}
```
### Option B — Local state (for quick testing)

If you don’t want a remote backend, you can use local state:


```hcl
terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}
```

### Environment and Terraform variables

To run the stack, define the following variables. Use **environment variables** for AWS credentials and **Terraform variables** for project-specific values.

| Variable               | Description                                                                 | Type        |
|-------------------------|-----------------------------------------------------------------------------|-------------|
| `AWS_ACCESS_KEY_ID`     | AWS access key ID provided as an environment variable.                      | env         |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key provided as an environment variable.                  | env         |
| `aws_region`            | AWS region where resources will be created.                                | terraform   |
| `admin_family_name`     | Family name of the root administrator user.                                | terraform   |
| `admin_given_name`      | Given name of the root administrator user.                                 | terraform   |
| `admin_password`        | Password for the root administrator user.                                  | terraform   |
| `admin_username`        | Username for the root administrator user.                                  | terraform   |
| `tags`                  | HCL list of tags to be applied as attributes to AWS resources.              | terraform   |



### AWS Policy for Terraform

Terraform needs permissions to create and manage the AWS resources defined in this project. Use the **minimum policy** provided at `infra/policy/My-Org-Tree.json`.

**Attach the policy**

1. In the AWS Console: **IAM → Policies → Create policy**.  
2. Paste the JSON from `infra/policy/My-Org-Tree.json` and create the policy.
3. Attach the policy to the **IAM user or role** whose credentials (Access Key ID / Secret) Terraform will use.

## Description

### AWS Infrastructure

This project provisions a **serverless** architecture that powers the application end-to-end:

- **Amazon S3** — hosts the single-page application (SPA).
- **AWS CloudFront** — serves as the public entry point for the SPA.
- **Amazon Cognito** - handles the user credentials and authentification
- **Amazon API Gateway** — public entry point for API requests from the SPA.
- **AWS Dynamo DB** - Handle the data logic and storage for operations
- **AWS Lambda** — stateless functions handling the business logic.
- **Amazon CloudWatch Logs** — centralized logging for debugging and traceability.

<img src="README-imgs/Architecture.png" alt="Architecture diagram" style="width:500px;">

**How it works**

1. The SPA is stored in an S3 bucket, which is secured with an Origin Access Control (OAC) so that only CloudFront can serve its content.  
2. CloudFront acts as the public entry point, delivering the SPA to users.  
3. User interactions trigger API requests routed through API Gateway.  
4. API Gateway invokes the appropriate Lambda functions.  
5. Lambdas handle the request and return the response to the SPA.  
6. API activity is logged in **CloudWatch Logs**.  


---

### The Web Application

The frontend is a single-page website hosted on S3:

<img src="README-imgs/website.png" alt="Website screenshot" style="width:500px;">

**Features**

- Search by movie title.
- Optional filters:
  - **Country** (first dropdown).
  - **Streaming provider** (second dropdown).

---

### Accessing the Application

After applying the Terraform configuration, use the URL printed in the Terraform **outputs** to open the website:

<img src="README-imgs/outputs.png" alt="Terraform outputs showing the website URL" style="width:500px;">


## Main Functions

### Code layout
- `search.mjs` and `watch.mjs` — Lambda handlers.
- `core.js` — shared helpers used by `watch.mjs` (the `/watch` Lambda). The `/search` Lambda does **not** depend on it.

### Workflow

#### Search for matches (`/search` Lambda)
Queries TMDB for titles matching the user’s input. Runs standalone and does not require `core.js`.

#### Resolve a title
`resolveTitle()` asks TMDB for detailed metadata (IDs, release year, runtime, etc.) for the selected movie.

#### Filter by provider
Because TMDB cannot filter providers in the query itself, `pickStreaming()` filters the provider list **after** retrieval to keep only the user-selected services (and country, if supplied).

#### Orchestrate “where to stream”
`whereToStream()` combines `resolveTitle()` and `pickStreaming()` into a single flow. It is called by the `/watch` Lambda (`watch.mjs`) to keep the handler small while centralizing API calls and filtering logic.

---

## Possible Improvements

- **Tighten IAM**: replace wildcard actions/resources with explicit ARNs; restrict each Lambda’s execution role to only required permissions.
- **Secret management**: store `tmdb_key` in AWS Secrets Manager or SSM Parameter Store (with KMS)
- **Observability**: generate detailed logs of API actions to improve traceability and make debugging more convenient.