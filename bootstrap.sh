#!/usr/bin/env bash
# bootstrap.sh
# Creates the Linode Object Storage bucket used as the Terraform state backend.
# Run this ONCE before `terraform init`. It is safe to re-run (bucket creation
# is idempotent via the `|| true` guard).
#
# Prerequisites:
#   pip install linode-cli
#   export LINODE_CLI_TOKEN="your_linode_personal_access_token"
#   export AWS_ACCESS_KEY_ID="<access_key>"      # set AFTER running this script
#   export AWS_SECRET_ACCESS_KEY="<secret_key>"  # from the keys-create output below

set -euo pipefail

CLUSTER="${LINODE_OBJ_CLUSTER:-us-east-1}"
BUCKET="linode-landingzone-state"
KEY_LABEL="terraform-state-key"

# ---- Preflight ----
echo "==> Checking linode-cli..."
if ! command -v linode-cli &>/dev/null; then
  echo "ERROR: linode-cli not found. Install with: pip install linode-cli"
  exit 1
fi

if [[ -z "${LINODE_CLI_TOKEN:-}" ]]; then
  echo "ERROR: LINODE_CLI_TOKEN is not set."
  echo "  export LINODE_CLI_TOKEN=your_personal_access_token"
  exit 1
fi

# ---- Create bucket ----
echo "==> Creating Object Storage bucket '${BUCKET}' in cluster '${CLUSTER}'..."
linode-cli obj mb "s3://${BUCKET}" --cluster "${CLUSTER}" || true
echo "    Bucket ready."

# ---- Create scoped access key ----
echo ""
echo "==> Generating Object Storage access key '${KEY_LABEL}'..."
echo "    (scoped read_write to '${BUCKET}' in '${CLUSTER}')"
echo ""
linode-cli object-storage keys-create \
  --label "${KEY_LABEL}" \
  --bucket_access "[{\"cluster\":\"${CLUSTER}\",\"bucket_name\":\"${BUCKET}\",\"permissions\":\"read_write\"}]"

echo ""
echo "======================================================================"
echo "  NEXT STEPS"
echo "======================================================================"
echo ""
echo "  1. Copy the access_key and secret_key from the output above."
echo ""
echo "  2. Export them so Terraform can authenticate to the S3 backend:"
echo "       export AWS_ACCESS_KEY_ID='<access_key>'"
echo "       export AWS_SECRET_ACCESS_KEY='<secret_key>'"
echo ""
echo "  3. Also add them to terraform.tfvars:"
echo "       linode_access_key = \"<access_key>\""
echo "       linode_secret_key = \"<secret_key>\""
echo ""
echo "  4. Run terraform init from the infrastructure/ directory:"
echo "       cd infrastructure && terraform init"
echo ""
echo "  5. Then plan and apply:"
echo "       terraform plan -out=tfplan"
echo "       terraform apply tfplan"
echo "======================================================================"
