#!/usr/bin/env bash
set -euo pipefail

# Safe phase-2 apply: create workload instances only.
# This intentionally excludes Akamai resources.

MODE="${1:-plan}"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_FILE="$ROOT_DIR/phase2.targets"
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

cd "$ROOT_DIR"

if [[ ! -f "terraform.tfvars" ]]; then
  echo "Missing terraform.tfvars in $ROOT_DIR"
  echo "Copy terraform.tfvars.example to terraform.tfvars and fill in real values first."
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

echo "Running terraform plan for Phase 2 workload instances..."
"$TERRAFORM_BIN" plan "${TARGET_ARGS[@]}" -out=phase2.tfplan

if [[ "$MODE" == "apply" ]]; then
  echo "Applying phase2.tfplan..."
  "$TERRAFORM_BIN" apply phase2.tfplan
  echo "Phase 2 apply complete."
else
  echo "Plan complete: phase2.tfplan"
  echo "To apply this plan, run: ./apply_phase2.sh apply"
fi
