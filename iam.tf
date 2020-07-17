# Create service account for cluster nodes
resource "google_service_account" "cluster" {
  account_id   = "${var.environment}-${var.name}"
  display_name = "Service account for cluster ${var.name}"
}

# Assign monitoring roles to push logs and metrics
resource "google_project_iam_member" "logging_log_writer" {
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.cluster.email}"
}

resource "google_project_iam_member" "monitoring_metric_writer" {
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.cluster.email}"
}

resource "google_project_iam_member" "monitoring_viewer" {
  role   = "roles/monitoring.viewer"
  member = "serviceAccount:${google_service_account.cluster.email}"
}

# Assign storage viewer to access private GCR images
resource "google_project_iam_member" "storage_object_viewer" {
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cluster.email}"
}
