output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.users.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.app.id
}

output "api_base_url" {
  value = aws_apigatewayv2_stage.dev.invoke_url
}

output "dynamodb_table" {
  value = aws_dynamodb_table.items.name
}
