output "log_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail and Config logs"
  value       = aws_s3_bucket.logs.bucket
}

output "kms_key_arn" {
  description = "ARN of the KMS key encrypting log data"
  value       = aws_kms_key.logs.arn
}

output "cloudtrail_trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = try(aws_cloudtrail.main[0].arn, null)
}

output "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = try(aws_config_configuration_recorder.main[0].name, null)
}
