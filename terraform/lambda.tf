# IAM role for Lambda
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "crud_lambda_role" {
  name               = "${var.project}-${var.env}-crud-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

# Inline policy for DynamoDB + Logs
data "aws_iam_policy_document" "crud_policy_doc" {
  statement {
    sid     = "DynamoCrud"
    effect  = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query"
    ]
    resources = [aws_dynamodb_table.items.arn]
  }

  statement {
    sid     = "Logs"
    effect  = "Allow"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "crud_policy" {
  name   = "${var.project}-${var.env}-crud-policy"
  policy = data.aws_iam_policy_document.crud_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "crud_attach" {
  role       = aws_iam_role.crud_lambda_role.name
  policy_arn = aws_iam_policy.crud_policy.arn
}

# Lambda function (points to built zip)
variable "crud_zip_path" {
  type    = string
  default = "../lambda/build/crud.zip"
}

resource "aws_lambda_function" "crud" {
  function_name    = "${var.project}-${var.env}-crud"
  role             = aws_iam_role.crud_lambda_role.arn
  filename         = var.crud_zip_path
  source_code_hash = filebase64sha256(var.crud_zip_path)
  handler          = "app.handler"
  runtime          = "python3.11"
  timeout          = 10
  memory_size      = 512

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
    }
  }

  tags = local.common_tags
}
