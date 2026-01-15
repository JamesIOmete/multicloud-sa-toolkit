locals {
  base_tags = {
    "toolkit"    = "multicloud-sa-toolkit"
    "use_case"   = "01-landing-zone-lite"
    "managed_by" = "terraform"
  }

  tags = merge(local.base_tags, var.tags)

  bucket_name = var.log_bucket_name != "" ? var.log_bucket_name : format("mcsa-uc01-logs-%s", data.aws_caller_identity.current.account_id)
  kms_alias   = var.kms_alias != "" ? var.kms_alias : "alias/mcsa-uc01-logs"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "aws_kms_key" "logs" {
  description             = "UC01 logging bucket encryption key"
  enable_key_rotation     = var.kms_key_rotation_enabled
  deletion_window_in_days = var.kms_deletion_window

  tags = local.tags
}

resource "aws_kms_alias" "logs" {
  name          = local.kms_alias
  target_key_id = aws_kms_key.logs.key_id
}

resource "aws_s3_bucket" "logs" {
  bucket = local.bucket_name

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.logs.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "retain-logs"
    status = "Enabled"

    expiration {
      days = var.s3_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.log_bucket.json
}

data "aws_iam_policy_document" "log_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.${data.aws_partition.current.dns_suffix}"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.${data.aws_partition.current.dns_suffix}"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = ["${aws_s3_bucket.logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }

    condition {
      test     = "StringLike"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.logs.arn]
    }
  }

  dynamic "statement" {
    for_each = var.enable_config ? [1] : []
    content {
      sid    = "AWSConfigWrite"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["config.${data.aws_partition.current.dns_suffix}"]
      }

      actions = [
        "s3:PutBucketAcl",
        "s3:PutObject"
      ]

      resources = [
        aws_s3_bucket.logs.arn,
        "${aws_s3_bucket.logs.arn}/config/*"
      ]

      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }

      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-server-side-encryption"
        values   = ["aws:kms"]
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "trail" {
  count = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = var.cloudwatch_retention_days

  kms_key_id = aws_kms_key.logs.arn

  tags = local.tags
}

resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  count = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  name = "${var.name_prefix}-cloudtrail-cw"

  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume.json

  tags = local.tags
}

data "aws_iam_policy_document" "cloudtrail_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.${data.aws_partition.current.dns_suffix}"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch" {
  count = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  name   = "${var.name_prefix}-cloudtrail-cw"
  role   = aws_iam_role.cloudtrail_to_cloudwatch[0].id
  policy = data.aws_iam_policy_document.cloudtrail_to_cloudwatch[0].json
}

data "aws_iam_policy_document" "cloudtrail_to_cloudwatch" {
  count = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream"
    ]

    resources = [
      format("%s:*", aws_cloudwatch_log_group.trail[0].arn)
    ]
  }
}

resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  include_global_service_events = true
  is_multi_region_trail         = var.cloudtrail_multi_region
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.logs.arn
  enable_logging                = true
  cloud_watch_logs_group_arn    = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.trail[0].arn : null
  cloud_watch_logs_role_arn     = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_to_cloudwatch[0].arn : null

  tags = local.tags
}

resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0

  name = "${var.name_prefix}-config"

  assume_role_policy = data.aws_iam_policy_document.config_assume.json

  tags = local.tags
}

data "aws_iam_policy_document" "config_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.${data.aws_partition.current.dns_suffix}"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  count = var.enable_config ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config ? 1 : 0

  name     = "${var.name_prefix}-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = var.config_record_all_supported
    include_global_resource_types = var.config_include_global_resource_types
  }
}

resource "aws_config_delivery_channel" "main" {
  count = var.enable_config ? 1 : 0

  name           = "${var.name_prefix}-channel"
  s3_bucket_name = aws_s3_bucket.logs.bucket
  s3_key_prefix  = "config"

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  count = var.enable_config ? 1 : 0

  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}