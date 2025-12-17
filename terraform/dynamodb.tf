resource "aws_dynamodb_table" "main" {
  name         = "${var.app_name}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.app_name}-table"
      Description = "DynamoDB table for application data storage"
    }
  )
}
