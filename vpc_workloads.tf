# vpc_workloads.tf
# Creates VPCs, subnets, and compute instances for all five environments.
#
# Fixes vs. original document:
#   - Added missing prod_vpc and dev_vpc resources (original only declared
#     365DBPartner_vpc but referenced the others from instances).
#   - Replaced top-level `vpc_id` on linode_instance (not a valid argument in
#     provider v2.x) with `interface` blocks — the correct way to attach an
#     instance to a VPC subnet.
#   - Added `image` argument (required for Linode instance creation).
#   - Added management_vpc for the bastion/jumpbox isolation.
#   - 365DBPartner VPC label renamed to avoid leading-digit TF resource name issue.

# ---------------------------------------------------------------------------
# VPCs
# ---------------------------------------------------------------------------

resource "linode_vpc" "management_vpc" {
  label       = "management-vpc"
  region      = var.linode_region
  description = "Management / bastion host VPC - no application workloads."
}

resource "linode_vpc" "prod_vpc" {
  label       = "workloads-production-vpc"
  region      = var.linode_region
  description = "Production workloads - strict WAF and firewall rules."
}

resource "linode_vpc" "dev_vpc" {
  label       = "workloads-development-vpc"
  region      = var.linode_region
  description = "Development / non-production - relaxed rules, smaller instance types."
}

resource "linode_vpc" "partner_vpc" {
  label       = "365DBPartner-production-vpc"
  region      = var.linode_region
  description = "Isolated VPC for 365DBPartner modules - full SDLC Dev->Prod."
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------

resource "linode_vpc_subnet" "management_subnet" {
  vpc_id = linode_vpc.management_vpc.id
  label  = "management-subnet"
  ipv4   = "10.0.0.0/24"
}

resource "linode_vpc_subnet" "prod_subnet" {
  vpc_id = linode_vpc.prod_vpc.id
  label  = "prod-subnet"
  ipv4   = "10.1.0.0/24"
}

resource "linode_vpc_subnet" "dev_subnet" {
  vpc_id = linode_vpc.dev_vpc.id
  label  = "dev-subnet"
  ipv4   = "10.2.0.0/24"
}

resource "linode_vpc_subnet" "partner_subnet" {
  vpc_id = linode_vpc.partner_vpc.id
  label  = "365DBPartner-subnet"
  ipv4   = "10.3.0.0/24"
}

# ---------------------------------------------------------------------------
# Compute instances
# ---------------------------------------------------------------------------

# Production API server — dedicated CPU, strict firewall, no public interface.
# Traffic reaches it only through the NodeBalancer/load balancer on port 443.
resource "linode_instance" "workload_production" {
  label  = "api-prod-01"
  tags   = ["environment:production", "workload:api"]
  region = var.linode_region
  type   = "g6-dedicated-4"
  image  = var.linode_instance_image

  # Attach to the production Cloud Firewall.
  firewall_id = linode_firewall.prod_firewall.id

  # Public interface — required to allow outbound updates/package installs.
  # Inbound is blocked by the Cloud Firewall except from the internal LB CIDR.
  interface {
    purpose = "public"
  }

  # VPC interface — private communication within the production subnet.
  interface {
    purpose   = "vpc"
    subnet_id = linode_vpc_subnet.prod_subnet.id
  }
}

# 365DBPartner module server — isolated VPC, production-grade instance.
resource "linode_instance" "workload_partner" {
  label  = "partner-prod-01"
  tags   = ["environment:partner", "platform:365dbpartner"]
  region = var.linode_region
  type   = "g6-standard-4"
  image  = var.linode_instance_image

  firewall_id = linode_firewall.prod_firewall.id

  interface {
    purpose = "public"
  }

  interface {
    purpose   = "vpc"
    subnet_id = linode_vpc_subnet.partner_subnet.id
  }
}
