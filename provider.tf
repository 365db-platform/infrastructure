# Akamai provider reads credentials from ~/.edgerc (Management account).
# Generate the .edgerc file via Akamai Control Center → Identity & Access →
# API Clients → Create API Client.
provider "akamai" {
  edgerc = "~/.edgerc"
}

# Linode provider uses a Personal Access Token.
# Generate at: https://cloud.linode.com/profile/tokens
provider "linode" {
  token             = var.linode_api_token
  obj_use_temp_keys = true
}
