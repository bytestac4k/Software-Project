# HTTP API v2
resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project}-${var.env}-api"
  protocol_type = "HTTP"
  tags          = local.common_tags
}

# Cognito JWT authorizer
locals {
  cognito_issuer   = "https://${aws_cognito_user_pool.users.endpoint}"
  cognito_audience = [aws_cognito_user_pool_client.app.id]
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.http.id
  name             = "CognitoJWT"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = local.cognito_audience
    issuer   = local.cognito_issuer
  }
}

# Lambda integration (proxy)
resource "aws_apigatewayv2_integration" "crud_integration" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.crud.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Catch-all route, protected by JWT
resource "aws_apigatewayv2_route" "default" {
  api_id              = aws_apigatewayv2_api.http.id
  route_key           = "$default"
  target              = "integrations/${aws_apigatewayv2_integration.crud_integration.id}"
  authorizer_id       = aws_apigatewayv2_authorizer.jwt.id
  authorization_type  = "JWT"
}

resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "dev"
  auto_deploy = true
  tags        = local.common_tags
}

# Permission for API GW to invoke Lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crud.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
