variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west1"
}

# Supabase
variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  sensitive   = true
}

variable "supabase_service_key" {
  description = "Supabase service role key (bypasses RLS)"
  type        = string
  sensitive   = true
}

# GoCardless
variable "gc_secret_id" {
  description = "GoCardless API secret ID"
  type        = string
  sensitive   = true
}

variable "gc_secret_key" {
  description = "GoCardless API secret key"
  type        = string
  sensitive   = true
}
