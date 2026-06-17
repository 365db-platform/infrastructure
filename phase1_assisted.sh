#!/usr/bin/env bash
set -euo pipefail

# Assisted phase-1 runner for macOS/Linux.
# This does NOT use Linode account username/password.
# It uses a Linode API token and Object Storage keys entered securely at runtime.

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

# Ensure user-local binaries (linode-cli, etc.) are discoverable.
export PATH="$HOME/.local/bin:$PATH"

TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
if ! command -v "$TERRAFORM_BIN" >/dev/null 2>&1; then
  if [[ -x "$HOME/.local/bin/terraform" ]]; then
    TERRAFORM_BIN="$HOME/.local/bin/terraform"
  fi
fi

if ! command -v "$TERRAFORM_BIN" >/dev/null 2>&1; then
  echo "Terraform not found. Install it first or set TERRAFORM_BIN=/path/to/terraform"
  exit 1
fi

if ! command -v linode-cli >/dev/null 2>&1; then
  echo "linode-cli not found. Install with: pip3 install --user linode-cli"
  exit 1
fi

if [[ ! -f terraform.tfvars ]]; then
  cp terraform.tfvars.example terraform.tfvars
  echo "Created terraform.tfvars from example. Fill non-secret placeholders before rerunning."
  echo "Required: akamai_root_group_id, akamai_contract_id, akamai_group_id, CIDRs, emails."
  exit 1
fi

if [[ -z "${LINODE_CLI_TOKEN:-}" ]]; then
  read -r -s -p "Enter LINODE_CLI_TOKEN (Personal Access Token): " LINODE_CLI_TOKEN
  echo ""
  export LINODE_CLI_TOKEN
fi

# Use the same token for Terraform Linode provider auth.
if grep -qE '^linode_api_token[[:space:]]*=' terraform.tfvars; then
  sed -i '' "s|^linode_api_token[[:space:]]*=.*$|linode_api_token   = \"${LINODE_CLI_TOKEN}\"|" terraform.tfvars
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
  read -r -p "Enter AWS_ACCESS_KEY_ID (Linode Object Storage key): " AWS_ACCESS_KEY_ID
  export AWS_ACCESS_KEY_ID
fi

if [[ -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  read -r -s -p "Enter AWS_SECRET_ACCESS_KEY (Linode Object Storage secret): " AWS_SECRET_ACCESS_KEY
  echo ""
  export AWS_SECRET_ACCESS_KEY
fi

# Keep local session env in a file for convenience (gitignored).
ENV_FILE=".env.phase1.local"
cat > "$ENV_FILE" <<EOF
export LINODE_CLI_TOKEN='${LINODE_CLI_TOKEN}'
export AWS_ACCESS_KEY_ID='${AWS_ACCESS_KEY_ID}'
export AWS_SECRET_ACCESS_KEY='${AWS_SECRET_ACCESS_KEY}'
EOF
chmod 600 "$ENV_FILE"

# Ensure backend creds are also persisted in tfvars for provider-level Object Storage operations.
if grep -qE '^linode_access_key[[:space:]]*=' terraform.tfvars; then
  sed -i '' "s|^linode_access_key[[:space:]]*=.*$|linode_access_key  = \"${AWS_ACCESS_KEY_ID}\"|" terraform.tfvars
fi
if grep -qE '^linode_secret_key[[:space:]]*=' terraform.tfvars; then
  sed -i '' "s|^linode_secret_key[[:space:]]*=.*$|linode_secret_key  = \"${AWS_SECRET_ACCESS_KEY}\"|" terraform.tfvars
fi

# Run safe phase-1 plan/apply flow.
./apply_phase1.sh

read -r -p "Apply phase1.tfplan now? (yes/no): " APPLY_NOW
if [[ "$APPLY_NOW" == "yes" ]]; then
  ./apply_phase1.sh apply
fi

echo "Done. To reuse env vars in a new shell, run: source $ROOT_DIR/.env.phase1.local"
