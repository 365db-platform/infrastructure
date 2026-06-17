#!/usr/bin/env bash
set -euo pipefail

# Safe phase-3 apply: Akamai IAM + AppSec only.
# This script enables Akamai resources explicitly and verifies real credentials
# before planning or applying.

MODE="${1:-plan}"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_FILE="$ROOT_DIR/phase3.targets"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"

if ! command -v "$TERRAFORM_BIN" >/dev/null 2>&1; then
  if [[ -x "$HOME/.local/bin/terraform" ]]; then
    TERRAFORM_BIN="$HOME/.local/bin/terraform"
  fi
fi

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "Missing target file: $TARGET_FILE"
  exit 1
fi

if ! command -v "$TERRAFORM_BIN" >/dev/null 2>&1; then
  echo "terraform is not installed or not on PATH."
  exit 1
fi

if [[ ! -f "$HOME/.edgerc" ]]; then
  echo "Missing ~/.edgerc (required for Akamai provider authentication)."
  exit 1
fi

cd "$ROOT_DIR"

if [[ ! -f "terraform.tfvars" ]]; then
  echo "Missing terraform.tfvars in $ROOT_DIR"
  echo "Copy terraform.tfvars.example to terraform.tfvars and fill in real values first."
  exit 1
fi

read_tfvar() {
  local key="$1"
  awk -F'=' -v k="$key" '
    $1 ~ "^[[:space:]]*" k "[[:space:]]*$" {
      v=$2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      gsub(/^"|"$/, "", v)
      print v
      exit
    }
  ' terraform.tfvars
}

CONTRACT_ID="$(read_tfvar akamai_contract_id || true)"
GROUP_ID="$(read_tfvar akamai_group_id || true)"
ROOT_GROUP_ID="$(read_tfvar akamai_root_group_id || true)"

if [[ -z "$CONTRACT_ID" || "$CONTRACT_ID" == YOUR_* ]]; then
  echo "Invalid akamai_contract_id in terraform.tfvars (still placeholder or empty)."
  exit 1
fi

if [[ -z "$GROUP_ID" || "$GROUP_ID" == "67890" ]]; then
  echo "Invalid akamai_group_id in terraform.tfvars (still placeholder or empty)."
  exit 1
fi

if [[ -z "$ROOT_GROUP_ID" || "$ROOT_GROUP_ID" == "12345" ]]; then
  echo "Invalid akamai_root_group_id in terraform.tfvars (still placeholder or empty)."
  exit 1
fi

RESOURCES=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  RESOURCES+=("$line")
done < "$TARGET_FILE"

if [[ ${#RESOURCES[@]} -eq 0 ]]; then
  echo "No targets defined in $TARGET_FILE"
  exit 1
fi

TARGET_ARGS=()
for r in "${RESOURCES[@]}"; do
  TARGET_ARGS+=("-target=$r")
done

echo "Initializing Terraform..."
"$TERRAFORM_BIN" init -upgrade

echo "Running terraform plan for Phase 3 Akamai resources..."
"$TERRAFORM_BIN" plan -var='enable_akamai=true' "${TARGET_ARGS[@]}" -out=phase3.tfplan

if [[ "$MODE" == "apply" ]]; then
  echo "Applying phase3.tfplan..."
  "$TERRAFORM_BIN" apply phase3.tfplan
  echo "Phase 3 apply complete."
else
  echo "Plan complete: phase3.tfplan"
  echo "To apply this plan, run: ./apply_phase3.sh apply"
fi
