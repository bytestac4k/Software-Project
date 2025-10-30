# Cognito User Pool + App Client + Groups
resource "aws_cognito_user_pool" "users" {
  name                     = "${var.project}-${var.env}-users"
  auto_verified_attributes = ["email"]
  tags                     = local.common_tags
}

resource "aws_cognito_user_pool_client" "app" {
  name                                 = "${var.project}-${var.env}-client"
  user_pool_id                         = aws_cognito_user_pool.users.id
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email"]
  callback_urls                        = ["http://localhost:5173"]
  logout_urls                          = ["http://localhost:5173"]
  tags                                 = local.common_tags
}

resource "aws_cognito_user_group" "admin" {
  name         = "Admin"
  user_pool_id = aws_cognito_user_pool.users.id
  description  = "Administrators"
}

resource "aws_cognito_user_group" "member" {
  name         = "Member"
  user_pool_id = aws_cognito_user_pool.users.id
  description  = "Standard members"
}
