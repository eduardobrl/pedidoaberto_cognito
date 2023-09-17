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
    organization = "pedidoaberto"

    workspaces {
      name = "pedidoaberto_cognito_hom"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_cognito_user_pool" "usuario_user_pool" {
  name                = "${var.app_name}-${var.microservice_name}-usuario"
  username_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }

    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }
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


resource "aws_cognito_user_group" "usuario_user_group_usuario_wishlist" {
  name         = "usuario_wishlist"
  user_pool_id = aws_cognito_user_pool.usuario_user_pool.id
  description  = "Grupo de usuario"
  precedence   = 30
  role_arn     = aws_iam_role.group_role.arn
}

resource "aws_cognito_user_group" "usuario_user_group_admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.usuario_user_pool.id
  description  = "Grupo de Usuarios Administradores"
  precedence   = 1
  role_arn     = aws_iam_role.group_role.arn
}

resource "aws_ssm_parameter" "sellbridge_cognito_usuario_user_pool_arn" {
  name  = "sellbridge_cognito_usuario_user_pool_arn"
  type  = "String"
  value = aws_cognito_user_pool.usuario_user_pool.arn
}

resource "aws_cognito_user_pool_client" "pedidoaberto_frontend_client" {
  name = "pedidoaberto_frontend_client"

  user_pool_id = aws_cognito_user_pool.usuario_user_pool.id

  default_redirect_uri = ["localhost"]
  callback_urls        = ["localhost"]
  logout_urls          = ["localhost"]

  generate_secret     = false
  explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = "pedidoaberto"
  user_pool_id = aws_cognito_user_pool.usuario_user_pool.id
}

resource "aws_cognito_user_pool_ui_customization" "example" {
  client_id    = aws_cognito_user_pool_client.pedidoaberto_frontend_client.id
  css          = ".label-customizable {font-weight: 400;}"
  user_pool_id = aws_cognito_user_pool_domain.this.user_pool_id
}

