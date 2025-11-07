terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Fetch current project details
data "google_project" "project" {}

# 1️⃣ Enable Vertex AI Search API
resource "google_project_service" "discoveryengine" {
  service = "discoveryengine.googleapis.com"
}

# 2️⃣ Create Vertex AI Data Store (linked to your GCS PDF)
resource "google_discovery_engine_data_store" "cx_datastore" {
  location          = var.region
  data_store_id     = "cx-agent-datastore"
  display_name      = "CX Knowledge Datastore"
  industry_vertical = "GENERIC"
  content_config    = "NO_CONTENT"
  solution_types    = ["SOLUTION_TYPE_CHAT"]
}

# 3️⃣ Link GCS PDF (ingestion trigger)
resource "google_discovery_engine_document" "pdf_document" {
  project       = var.project_id
  location      = var.region
  data_store_id = google_discovery_engine_data_store.cx_datastore.data_store_id
  document_id   = "playbook-pdf"

  content {
    gcs_uri = "gs://${var.bucket_name}/DataStore.pdf"
  }

  title          = "R4B Playbook"
  content_type   = "CONTENT_TYPE_UNSPECIFIED"
}

# 4️⃣ Create CX Tool reference linking Agent <-> Data Store
resource "google_dialogflow_cx_tool" "datastore_link" {
  parent       = "projects/${var.project_id}/locations/${var.region}/agents/${var.agent_id}"
  display_name = "R4B Datastore Tool"
  description  = "Auto-linked Vertex AI Search data store for Dialogflow CX"
  
  data_store_spec {
    data_store_connections {
      data_store_type            = "UNSTRUCTURED"
      data_store                 = "projects/${data.google_project.project.number}/locations/${var.region}/collections/default_collection/dataStores/${google_discovery_engine_data_store.cx_datastore.data_store_id}"
      document_processing_mode   = "DOCUMENTS"
    }
    fallback_prompt {}
  }

  depends_on = [
    google_discovery_engine_data_store.cx_datastore,
    google_discovery_engine_document.pdf_document
  ]
}

output "data_store_reference" {
  value = google_discovery_engine_data_store.cx_datastore.id
}
