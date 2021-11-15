terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.48.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  backend "remote" {
    organization = "sellbridge"

    workspaces {
      name = "sellbridge-cognito-dev-workspace"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_cognito_user_pool" "fornecedor_user_pool" {
  name = "${var.app_name}-${var.microservice_name}-fornecedor"
}

resource "aws_cognito_user_pool" "vendedor_user_pool" {
  name = "${var.app_name}-${var.microservice_name}-vendedor"
}

resource "aws_cognito_user_pool" "usuario_user_pool" {
  name = "${var.app_name}-${var.microservice_name}-usuario"
}

resource "aws_iam_role" "group_role" {
  name = "user-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "us-east-1:12345678-dead-beef-cafe-123456790ab"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
EOF
}

resource "aws_cognito_user_group" "fornecedor_user_group" {
  name         = "user-group"
  user_pool_id = aws_cognito_user_pool.fornecedor_user_pool.id
  description  = "Managed by Terraform"
  precedence   = 42
  role_arn     = aws_iam_role.group_role.arn
}

resource "aws_cognito_user_group" "vendedor_user_group" {
  name         = "user-group"
  user_pool_id = aws_cognito_user_pool.vendedor_user_pool.id
  description  = "Managed by Terraform"
  precedence   = 42
  role_arn     = aws_iam_role.group_role.arn
}

resource "aws_cognito_user_group" "usuario_user_group" {
  name         = "user-group"
  user_pool_id = aws_cognito_user_pool.usuario_user_pool.id
  description  = "Managed by Terraform"
  precedence   = 42
  role_arn     = aws_iam_role.group_role.arn
}
