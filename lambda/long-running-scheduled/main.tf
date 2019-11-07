# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A LAMBDA FUNCTION
# This function will run on a scheduled basis. It will run an ECS Task to demonstrate how to handle long-running tasks
# that take longer than Lambda's 5-minute time limit.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region

  # Provider version 2.X series is the latest, but has breaking changes with 1.X series.
  version = "~> 2.6"

  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = [var.aws_account_id]
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE REMOTE STATE STORAGE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}

  # Only allow this Terraform version. Note that if you upgrade to a newer version, Terraform won't allow you to use an
  # older version, so when you upgrade, you should upgrade everyone on your team and your CI servers all at once.
  required_version = "= 0.12.9"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

module "lambda" {
  source = "git::git@github.com:gruntwork-io/package-lambda.git//modules/lambda?ref=v0.6.0"

  name        = "scheduled-example-${var.vpc_name}"
  description = "An example lambda function that shows how to use lambda and how to run an ECS task from a lambda function for long-running tasks"

  source_path = var.source_path
  runtime     = "python2.7"

  # The Lambda zip file will be extracted into /var/task. Our zip contains two folders: a src folder with our Lambda
  # code, including the handler, and a dependencies folder that has our dependencies. Below, we tell the Lambda
  # function to find its handler in the src folder (https://forums.aws.amazon.com/thread.jspa?messageID=667590) and
  # configure the PYTHONPATH environment variable so it knows where to find dependencies
  # (https://docs.python.org/2/using/cmdline.html#envvar-PYTHONPATH).
  handler = "src/index.handler"

  environment_variables = {
    PYTHONPATH = "/var/task/dependencies"

    # The lambda function will run this ECS task in the specified ECS cluster
    ecs_task    = "${aws_ecs_task_definition.example.family}:${aws_ecs_task_definition.example.revision}"
    ecs_cluster = data.terraform_remote_state.ecs_cluster.outputs.ecs_cluster_name
    aws_region  = var.aws_region
  }

  timeout     = 30
  memory_size = 128
}

# ---------------------------------------------------------------------------------------------------------------------
# SCHEDULE THE LAMBDA FUNCTION TO RUN ON A SCHEDULED BASIS
# Using the scheduled-lambda-job module, we can configure the lambda function to automatically run on a scheduled basis.
# ---------------------------------------------------------------------------------------------------------------------

module "scheduled" {
  source = "git::git@github.com:gruntwork-io/package-lambda.git//modules/scheduled-lambda-job?ref=v0.6.0"

  lambda_function_name = module.lambda.function_name
  lambda_function_arn  = module.lambda.function_arn
  schedule_expression  = "rate(1 day)"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ECS TASK THE LAMBDA FUNCTION CAN RUN AS AN EXAMPLE
# Purely as an example, this shows how to create an ECS Task that can be executed by the lambda function. Lambda
# functions are limited to 5 minutes of execution, so if you have a long-running job that you run on a scheduled basis,
# you can use a scheduled lambda function to run that job as an ECS Task in an ECS Cluster.
# ---------------------------------------------------------------------------------------------------------------------

# To keep the example simple, we are just running the Docker hello-world container, which will simply print "Hello,
# World" and exit: https://hub.docker.com/_/hello-world/
resource "aws_ecs_task_definition" "example" {
  family = "${var.vpc_name}-hello-world-example"

  container_definitions = <<EOF
[{
  "name": "hello-world-example",
  "image": "hello-world",
  "cpu": 10,
  "memory": 64,
  "essential": true
}]
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# GIVE THE LAMBDA FUNCTION PERMISSIONS TO RUN ECS TASKS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "run_ecs_tasks" {
  role   = module.lambda.iam_role_id
  policy = data.aws_iam_policy_document.run_ecs_tasks.json
}

data "aws_iam_policy_document" "run_ecs_tasks" {
  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = [aws_ecs_task_definition.example.arn]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PULL DATA FROM OTHER TERRAFORM TEMPLATES USING TERRAFORM REMOTE STATE
# These templates use Terraform remote state to access data from a number of other Terraform templates, all of which
# store their state in S3 buckets.
# ---------------------------------------------------------------------------------------------------------------------

data "terraform_remote_state" "ecs_cluster" {
  backend = "s3"

  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/services/ecs-cluster/terraform.tfstate"
  }
}
