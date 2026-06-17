# iam_management.tf
# Replicates the AWS Organizations five-account model using Akamai IAM groups.
# Each group scopes users and API credentials to one logical environment.
#
# NOTE: `granted_roles` values are numeric Akamai role IDs, which are
# account-specific. Find them via:
#   akamai iam list-roles   (requires Akamai CLI: npm install -g @akamai/cli)
# The placeholder values below must be replaced before first apply.

# ---------------------------------------------------------------------------
# Environment groups (one per AWS-equivalent account)
# ---------------------------------------------------------------------------

resource "akamai_iam_group" "environments" {
  for_each = var.enable_akamai ? toset(["Management", "Security", "Sandbox", "Logging", "Workloads"]) : toset([])

  name            = "Account_${each.value}"
  parent_group_id = var.akamai_root_group_id
}

# ---------------------------------------------------------------------------
# Custom roles
# ---------------------------------------------------------------------------

# Security Auditor — read-only visibility across all environments.
# Replace granted_roles IDs with real viewer role IDs from your Akamai account.
resource "akamai_iam_role" "security_auditor" {
  count = var.enable_akamai ? 1 : 0

  name        = "Security_Auditor_ReadOnly"
  description = "Read-only access scoped to the Security environment"

  # TODO: replace 0 with the actual numeric role ID for your Akamai viewer role.
  # Run: akamai iam list-roles | grep -i viewer
  granted_roles = []
}

# Network Engineer — manages VPC, Cloud Firewall, and NodeBalancers.
# TODO: replace with actual administrator role ID.
resource "akamai_iam_role" "network_engineer" {
  count = var.enable_akamai ? 1 : 0

  name        = "Network_Engineer"
  description = "Manage VPC, Cloud Firewall, and NodeBalancers"

  # TODO: replace with the actual numeric role ID for your Akamai admin role.
  granted_roles = []
}

# ---------------------------------------------------------------------------
# Outputs used by other modules
# ---------------------------------------------------------------------------

output "iam_group_ids" {
  description = "Map of environment name → Akamai IAM group ID"
  value = var.enable_akamai ? {
    for env, grp in akamai_iam_group.environments : env => grp.id
  } : null
}
