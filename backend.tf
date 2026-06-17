terraform {
  # Linode Object Storage is S3-compatible. The bucket must exist BEFORE running
  # `terraform init`. Run bootstrap.sh once to create it, then init.
  backend "s3" {
    bucket = "linode-landingzone-state"
    key    = "management/terraform.tfstate"

    # Linode Object Storage endpoint — format: <cluster>.linodeobjects.com
    endpoints = {
      s3 = "https://us-east-1.linodeobjects.com"
    }

    # Must be set even though Linode doesn't use AWS regions; use the cluster label.
    region = "us-east-1"

    # Required flags to bypass AWS-specific validation that doesn't apply to Linode.
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }

  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = ">= 5.0.0"
    }
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
  }

  required_version = ">= 1.5.0"
}
