# legacy_host.tf
# Tracks the existing 365DB pilot server without changing it.
# This keeps the current dev host under Terraform control while Phase 2
# continues to represent the new workload instances.

resource "linode_instance" "pilot_server_365db" {
  label  = "pilot_server_365db"
  tags   = ["365db", "bookings"]
  region = "fr-par"
  type   = "g6-dedicated-4"
  image  = "linode/ubuntu24.04"

  firewall_id = null

  lifecycle {
    ignore_changes = all
  }
}
