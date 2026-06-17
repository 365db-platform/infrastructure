# logging_bucket.tf
# Central audit bucket is created manually due provider/API timeout behavior.
# Terraform manages only the write-only log shipping key against that bucket.

locals {
  central_audit_bucket_name = "central-security-logs"
}

resource "linode_object_storage_bucket" "central_audit_logs" {
  region     = replace(var.linode_obj_cluster, "-1", "")
  label      = local.central_audit_bucket_name
  acl        = "private"
  versioning = true

  lifecycle_rule {
    id      = "immutable-retention"
    enabled = true

    expiration {
      days = 2555
    }

    noncurrent_version_expiration {
      days = 90
    }

    abort_incomplete_multipart_upload_days = 7
  }
}

resource "linode_object_storage_key" "log_writer" {
  label = "log-shipping-agent-key"

  bucket_access {
    region      = replace(var.linode_obj_cluster, "-1", "")
    bucket_name = local.central_audit_bucket_name
    permissions = "read_write"
  }
}

output "log_writer_access_key" {
  description = "Access key for log-shipping agents (write-only to audit bucket)."
  value       = linode_object_storage_key.log_writer.access_key
  sensitive   = true
}

output "log_writer_secret_key" {
  description = "Secret key for log-shipping agents."
  value       = linode_object_storage_key.log_writer.secret_key
  sensitive   = true
}
