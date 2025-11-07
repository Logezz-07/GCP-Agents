variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "GCP region (must match Dialogflow agent region)"
  type        = string
  default     = "us-central1"
}

variable "bucket_name" {
  description = "GCS bucket where the PDF resides"
  type        = string
}

variable "agent_id" {
  description = "Dialogflow CX agent ID"
  type        = string
}
