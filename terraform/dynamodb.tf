resource "aws_dynamodb_table" "items" {
  name         = "${var.project}_${var.env}_items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.common_tags
}
