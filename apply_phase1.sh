#!/usr/bin/env bash
set -euo pipefail

# Safe phase-1 apply: create only foundation resources.
# Intentionally excludes all linode_instance resources.

MODE="${1:-plan}"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_FILE="$ROOT_DIR/phase1.targets"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
SKIP_AKAMAI="${SKIP_AKAMAI:-auto}"

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
  if [[ "$SKIP_AKAMAI" == "1" ]]; then
    [[ "$line" == akamai_* ]] && continue
  elif [[ "$SKIP_AKAMAI" == "auto" ]]; then
    if [[ ! -f "$HOME/.edgerc" && "$line" == akamai_* ]]; then
      continue
    fi
  fi
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

echo "Running terraform plan for Phase 1 foundation resources..."
"$TERRAFORM_BIN" plan "${TARGET_ARGS[@]}" -out=phase1.tfplan

if [[ "$MODE" == "apply" ]]; then
  echo "Applying phase1.tfplan..."
  "$TERRAFORM_BIN" apply phase1.tfplan
  echo "Phase 1 apply complete."
else
  echo "Plan complete: phase1.tfplan"
  echo "To apply this plan, run: ./apply_phase1.sh apply"
fi
