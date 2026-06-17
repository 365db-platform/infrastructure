# outputs.tf
# Top-level outputs for the landing zone.
# Use `terraform output -json` to get structured values for downstream automation.

output "prod_vpc_id" {
  description = "ID of the Production VPC."
  value       = linode_vpc.prod_vpc.id
}

output "dev_vpc_id" {
  description = "ID of the Development VPC."
  value       = linode_vpc.dev_vpc.id
}

output "partner_vpc_id" {
  description = "ID of the 365DBPartner isolated VPC."
  value       = linode_vpc.partner_vpc.id
}

output "management_vpc_id" {
  description = "ID of the Management / bastion VPC."
  value       = linode_vpc.management_vpc.id
}

output "audit_log_bucket_label" {
  description = "Linode Object Storage bucket label for central audit logs."
  value       = "central-security-logs"
}

output "audit_log_bucket_endpoint" {
  description = "HTTPS endpoint for the central audit log bucket."
  value       = "https://central-security-logs.${var.linode_obj_cluster}.linodeobjects.com"
}

output "prod_firewall_id" {
  description = "ID of the Production Cloud Firewall."
  value       = linode_firewall.prod_firewall.id
}

output "dev_firewall_id" {
  description = "ID of the Development Cloud Firewall."
  value       = linode_firewall.dev_firewall.id
}

output "appsec_config_id" {
  description = "Akamai AppSec configuration ID."
  value       = var.enable_akamai ? akamai_appsec_configuration.security_config[0].config_id : null
}
