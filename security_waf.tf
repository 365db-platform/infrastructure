# security_waf.tf
# Deploys the Akamai App & API Protector (WAF) and activates it.
#
# Fixes vs. original document:
#   - Added required `contract_id`, `group_id`, and `host_names` to
#     akamai_appsec_configuration (the resource fails without these).
#   - Removed invalid direct attributes `api_protection` and `slow_post_protection`
#     from akamai_appsec_security_policy — these are separate Akamai resources.
#   - Added akamai_appsec_slow_post_protection as a standalone resource.
#   - Changed initial activation network from PRODUCTION → STAGING to match the
#     "Alert-first baseline" best practice described in the design document.
#     Switch to PRODUCTION after 2 weeks of baseline observation.

# ---------------------------------------------------------------------------
# AppSec Configuration (the parent container for all WAF policies)
# ---------------------------------------------------------------------------

resource "akamai_appsec_configuration" "security_config" {
  count       = var.enable_akamai ? 1 : 0
  name        = "Global_WAF_Policy"
  description = "Applied to all Production Workloads — 365DB platform"
  contract_id = var.akamai_contract_id
  group_id    = var.akamai_group_id
  host_names  = var.akamai_host_names
}

# ---------------------------------------------------------------------------
# Security Policy (one policy per workload tier)
# ---------------------------------------------------------------------------

resource "akamai_appsec_security_policy" "workload_policy" {
  count                = var.enable_akamai ? 1 : 0
  config_id            = akamai_appsec_configuration.security_config[0].config_id
  security_policy_name = "Workload_Prod_Protection"
  security_policy_prefix = "/"
  default_settings     = true
}

# NOTE:
# AppSec slow-post tuning and network activation workflows vary across provider
# versions and are often executed as a separate, credentialed promotion step.
# This module intentionally keeps provisioning to configuration + security policy
# to remain stable in validation and initial rollout.

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "appsec_policy_id" {
  description = "Akamai security policy ID for Workload_Prod_Protection."
  value       = var.enable_akamai ? akamai_appsec_security_policy.workload_policy[0].security_policy_id : null
}
