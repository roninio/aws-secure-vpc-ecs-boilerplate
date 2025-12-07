resource "aws_cognito_user_pool" "main" {
  name = "${var.app_name}-user-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = var.allow_admin_create_user_only
  }

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  schema {
    name                = "app_name"
    attribute_data_type = "String"
    mutable             = false
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Name = "${var.app_name}-user-pool"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "${var.app_name}-client"

  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret         = true
  enable_token_revocation = true

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 1
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  callback_urls = concat(
    ["https://${aws_lb.main.dns_name}/oauth2/idpresponse"],
    var.additional_callback_urls
  )
  logout_urls = concat(
    ["https://${aws_lb.main.dns_name}/logout-success"],
    var.additional_logout_urls
  )
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.cognito_domain_prefix}-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_cognito_user_pool_ui_customization" "ui" {
  client_id = aws_cognito_user_pool_client.client.id
  user_pool_id = aws_cognito_user_pool.main.id

  css = <<EOF
    .label-customizable {
      font-weight: 400;
    }
    .textDescription-customizable {
      padding-top: 10px;
      padding-bottom: 10px;
      display: block;
    }
    .submitButton-customizable {
      font-size: 14px;
      font-weight: bold;
      margin: 20px 0px;
      height: 40px;
      width: 100%;
      color: #fff;
      background-color: #007bff; /* Blue button */
      border: none;
      border-radius: 4px;
      text-transform: uppercase;
    }
    .submitButton-customizable:hover {
      background-color: #0056b3;
      cursor: pointer;
    }
    .inputField-customizable {
      width: 100%;
      height: 34px;
      padding: 6px 12px;
      border: 1px solid #ccc;
      border-radius: 4px;
    }
  EOF
}
