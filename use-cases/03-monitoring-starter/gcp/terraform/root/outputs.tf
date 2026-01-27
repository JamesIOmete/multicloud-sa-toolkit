output "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic."
  value       = google_pubsub_topic.topic.name
}

output "cloud_function_name" {
  description = "The name of the Cloud Function."
  value       = google_cloudfunctions2_function.function.name
}

output "notification_channel_id" {
  description = "The ID of the notification channel."
  value       = google_monitoring_notification_channel.sms.id
}
