output "backend_service_account" {
  value = google_service_account.wis_backend_api_sa.email
  description = "Backend service account email"
}

output "frontend_service_account" {
  value = google_service_account.wis_frontend_ui_sa.email
  description = "Frontend service account email"
}

output "database_connection" {
  value = google_sql_database_instance.wis_dev_db.connection_name
  description = "Database connection name"
}

output "frontend_bucket" {
  value = google_storage_bucket.frontend_assets.url
  description = "Frontend assets bucket URL"
}