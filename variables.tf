# ---------------------------------------------------------------------------
# Linode credentials
# ---------------------------------------------------------------------------

variable "linode_api_token" {
  description = "Linode Personal Access Token — used by the Linode provider."
  type        = string
  sensitive   = true
}

variable "linode_access_key" {
  description = "Linode Object Storage access key — used for bucket policy operations."
  type        = string
}

variable "linode_secret_key" {
  description = "Linode Object Storage secret key — used for bucket policy operations."
  type        = string
}

# ---------------------------------------------------------------------------
# Region / cluster
# ---------------------------------------------------------------------------

variable "linode_region" {
  description = "Linode region for compute and VPC resources (e.g. 'us-east', 'eu-west')."
  type        = string
  default     = "us-east"
}

variable "linode_obj_cluster" {
  description = <<-EOT
    Linode Object Storage cluster label. Must match the endpoint in backend.tf.
    Run `linode-cli obj list-clusters` to see available values.
  EOT
  type        = string
  default     = "us-east-1"
}

variable "linode_instance_image" {
  description = "Linode image to use for compute instances."
  type        = string
  default     = "linode/ubuntu22.04"
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "bastion_cidr" {
  description = <<-EOT
    CIDR of the management bastion / jumpbox allowed to SSH into instances.
    Example: "172.232.54.62/32" for the current 365DB host.
  EOT
  type        = string
  # No default — must be supplied explicitly to avoid accidental open SSH.
}

variable "internal_lb_cidr" {
  description = "CIDR of the internal load balancer subnet allowed to reach port 443 on production instances."
  type        = string
  default     = "192.168.1.0/24"
}

variable "partner_integration_cidrs" {
  description = "List of partner IP CIDRs allowed into the Sandbox environment (ports 80/443)."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------

variable "admin_users" {
  description = "List of admin email addresses to assign to the Management IAM group."
  type        = list(string)
  default     = ["admin@company.com", "secops@company.com"]
}

variable "akamai_root_group_id" {
  description = <<-EOT
    Akamai Control Center root group ID. Find it at:
    Control Center → Identity & Access → Groups → root group → copy the numeric ID.
  EOT
  type        = number
}

# ---------------------------------------------------------------------------
# Akamai AppSec / WAF
# ---------------------------------------------------------------------------

variable "enable_akamai" {
  description = "Enable Akamai AppSec and IAM resources. Keep false for Linode-only runs."
  type        = bool
  default     = false
}

variable "akamai_contract_id" {
  description = "Akamai contract ID (shown in Control Center → Contracts)."
  type        = string
}

variable "akamai_group_id" {
  description = "Akamai group ID that owns the AppSec configuration."
  type        = number
}

variable "akamai_host_names" {
  description = "Host names to protect with the Global WAF security configuration."
  type        = list(string)
  default     = ["365daybookings.com"]
}

variable "security_notification_email" {
  description = "Email address for WAF activation notifications and security alerts."
  type        = string
  default     = "security@company.com"
}
