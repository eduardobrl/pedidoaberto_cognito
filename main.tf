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


resource "aws_cognito_user_group" "usuario_user_group" {
  name         = "fornecedor"
  user_pool_id = aws_cognito_user_pool.usuario_user_pool.id
  description  = "Grupo de fornecedores"
  precedence   = 30
  role_arn     = aws_iam_role.group_role.arn
}

resource "aws_cognito_user_group" "usuario_user_group" {
  name         = "vendedor"
  user_pool_id = aws_cognito_user_pool.usuario_user_pool.id
  description  = "Grupo de vendedores"
  precedence   = 42
  role_arn     = aws_iam_role.group_role.arn
}

resource "aws_cognito_user_group" "usuario_user_group" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.usuario_user_pool.id
  description  = "Grupo de Usuarios Adminitradores"
  precedence   = 1
  role_arn     = aws_iam_role.group_role.arn
}

resource "aws_ssm_parameter" "sellbridge_cognito_usuario_user_pool_arn" {
  name  = "sellbridge_cognito_usuario_user_pool_arn"
  type  = "String"
  value = aws_cognito_user_pool.usuario_user_pool.arn
}
