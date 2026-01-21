locals {
  base_name = "${var.base_name}-${var.sandbox_id}"
  tags = merge({
    toolkit    = "multicloud-sa-toolkit",
    use_case   = "04-ephemeral-sandbox",
    env        = var.env,
    owner      = var.owner,
    managed_by = "terraform",
    sandbox_id = var.sandbox_id
  }, var.additional_tags)

  table_name = var.metadata_table_name != "" ? var.metadata_table_name : "${var.base_name}-metadata"
}

resource "time_static" "sandbox_created" {}

resource "aws_dynamodb_table" "sandboxes" {
  count        = var.create_metadata_table ? 1 : 0
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "sandbox_id"
  range_key    = "created_at"

  attribute {
    name = "sandbox_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = merge(local.tags, { Name = "${var.base_name}-metadata" })
}

resource "aws_dynamodb_table_item" "entry" {
  table_name = var.create_metadata_table ? aws_dynamodb_table.sandboxes[0].name : local.table_name
  hash_key   = "sandbox_id"
  range_key  = "created_at"

  item = jsonencode({
    sandbox_id = { S = var.sandbox_id }
    created_at = { S = time_static.sandbox_created.rfc3339 }
    ttl_hours  = { N = tostring(var.ttl_hours) }
    expires_at = { N = formatdate("1136239445", timeadd(time_static.sandbox_created.rfc3339, format("%dh", var.ttl_hours))) }
    status     = { S = "ACTIVE" }
  })
}

output "metadata_table_name" {
  value = var.create_metadata_table ? aws_dynamodb_table.sandboxes[0].name : local.table_name
}
