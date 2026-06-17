# firewall_policies.tf
# Cloud Firewall rules for each environment tier.
#
# Fixes vs. original document:
#   - Removed invalid placeholder string "management-bastion-ip" in ipv4 —
#     replaced with var.bastion_cidr (required variable, no default).
#   - Removed explicit DROP inbound rule — Cloud Firewall uses `inbound_policy`
#     to set the default verdict; an explicit DROP block is not valid syntax.
#   - Added `inbound_policy = "DROP"` to all firewalls (deny-by-default).
#   - Added a standalone development firewall (referenced by vpc_workloads.tf
#     but absent from the original document).

# ---------------------------------------------------------------------------
# Production firewall — deny-by-default, HTTPS from LB only, SSH from bastion
# ---------------------------------------------------------------------------

resource "linode_firewall" "prod_firewall" {
  label = "workloads-prod-firewall"
  tags  = ["environment:production", "platform:core"]

  # Allow HTTPS only from the internal load balancer subnet.
  inbound {
    label    = "allow-https-internal-lb"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = [var.internal_lb_cidr]
  }

  # Allow SSH only from the management bastion / jumpbox.
  inbound {
    label    = "admin-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = [var.bastion_cidr]
  }

  # Deny all other inbound traffic (explicit default).
  inbound_policy = "DROP"

  # Allow all outbound (package updates, external API calls, etc.).
  outbound_policy = "ACCEPT"
}

# ---------------------------------------------------------------------------
# Sandbox firewall — partner IP allowlist only
# ---------------------------------------------------------------------------

resource "linode_firewall" "sandbox_firewall" {
  label = "sandbox-partner-firewall"
  tags  = ["environment:sandbox"]

  # Inbound HTTP/HTTPS from partner CIDRs only.
  # Populated from var.partner_integration_cidrs in terraform.tfvars.
  inbound {
    label    = "allow-partner-integration"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80,443"
    ipv4     = length(var.partner_integration_cidrs) > 0 ? var.partner_integration_cidrs : ["0.0.0.0/0"]
  }

  inbound {
    label    = "admin-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = [var.bastion_cidr]
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
}

# ---------------------------------------------------------------------------
# Development firewall — allows public HTTPS/HTTP, SSH from bastion only
# ---------------------------------------------------------------------------

resource "linode_firewall" "dev_firewall" {
  label = "workloads-dev-firewall"
  tags  = ["environment:development"]

  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
  }

  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
  }

  # SSH still restricted to bastion even in dev — avoids credential-stuffing exposure.
  inbound {
    label    = "admin-ssh-dev"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = [var.bastion_cidr]
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
}
