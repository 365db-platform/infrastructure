# Infrastructure Implementation Log (Up To 2026-06-17)

## Scope
This log documents the implementation path from initial setup through the current stabilized state, plus what remains to complete.

## 1. Initial Starting Point
- Goal: Implement the AWS-style landing-zone pattern on Linode + Akamai using Terraform.
- Workspace path: /Users/sdg/Documents/365db/booking-parent/infrastructure
- Inputs available at start:
  - Terraform configuration skeleton for Linode networking, firewalling, object storage, and Akamai IAM/AppSec.
  - Placeholder values in terraform variables for Akamai-specific IDs.
- Operating constraints encountered:
  - Local shell differences on macOS/zsh.
  - Provider/version schema mismatches during early execution.
  - State/back-end auth interruptions during initial applies.

## 2. Foundation Build and Reconciliation (Phase 1)
### Implemented
- Terraform binary path stabilized to local executable:
  - $HOME/.local/bin/terraform
- Remote backend configured for Linode Object Storage S3-compatible state.
- Foundation resources created/imported and reconciled:
  - VPCs: dev, prod, management, partner
  - Subnets: dev, prod, management, partner
  - Firewalls: dev, prod, sandbox
  - Central audit bucket
  - Log-writer object storage key

### Recovery work completed during Phase 1
- Corrected provider/resource schema mismatches.
- Fixed backend credential and object key scope issues.
- Imported already-created resources after partial apply/state-write failures.
- Normalized bucket/key management to provider-supported arguments.

## 3. Workload Provisioning (Phase 2)
### Implemented
- Created workload instances in controlled phase:
  - workload_production (Linode ID 99319081)
  - workload_partner (Linode ID 99319084)
- Imported existing live pilot host as managed legacy resource:
  - pilot_server_365db (Linode ID 72015814)
- Added lifecycle guard on legacy host to prevent accidental mutation:
  - ignore_changes = all

### Safety changes applied
- Removed duplicate development workload definition to prevent unintended instance creation.
- Limited phase-2 target list to only intended workload instances.

## 4. Drift Cleanup and Stabilization
### Implemented
- Applied targeted and full drift reconciliations.
- Resolved repeated VPC description drift by normalizing text to provider-stable ASCII values.
- Migrated deprecated Linode object storage bucket argument:
  - from cluster to region

### Validation outcome
- terraform validate: passes
- terraform plan: no changes

## 5. Akamai Gating and Safe Enablement Controls
### Implemented
- Added feature toggle:
  - variable enable_akamai (default false)
- Wrapped Akamai IAM and AppSec resources so they are opt-in.
- Made Akamai outputs conditional to avoid false plan churn in Linode-only mode.
- Added dedicated Akamai phase automation:
  - apply_phase3.sh
  - phase3.targets
- Added guardrails in apply_phase3.sh:
  - Requires ~/.edgerc
  - Rejects placeholder/empty Akamai IDs in terraform.tfvars
  - Forces enable_akamai=true only for phase-3 plan/apply

### Verified behavior
- Running ./apply_phase3.sh plan currently stops safely because Akamai contract/group/root IDs are still placeholders.

## 6. Current Managed State (Authoritative Terraform Snapshot)
From terraform state list and terraform output:

### Resources in state
- linode_firewall.dev_firewall
- linode_firewall.prod_firewall
- linode_firewall.sandbox_firewall
- linode_instance.pilot_server_365db
- linode_instance.workload_partner
- linode_instance.workload_production
- linode_object_storage_bucket.central_audit_logs
- linode_object_storage_key.log_writer
- linode_vpc.dev_vpc
- linode_vpc.management_vpc
- linode_vpc.partner_vpc
- linode_vpc.prod_vpc
- linode_vpc_subnet.dev_subnet
- linode_vpc_subnet.management_subnet
- linode_vpc_subnet.partner_subnet
- linode_vpc_subnet.prod_subnet

### Key outputs
- audit_log_bucket_endpoint = https://central-security-logs.us-east-1.linodeobjects.com
- audit_log_bucket_label = central-security-logs
- dev_firewall_id = 42676195
- dev_vpc_id = 519536
- management_vpc_id = 519538
- partner_vpc_id = 519539
- prod_firewall_id = 42676194
- prod_vpc_id = 519537
- log_writer_access_key = sensitive
- log_writer_secret_key = sensitive

## 7. What Is Next To Complete
## A) Complete Akamai deployment (remaining work)
1. Update terraform.tfvars with real Akamai values:
   - akamai_contract_id
   - akamai_group_id
   - akamai_root_group_id
2. Ensure valid Akamai API credentials file exists:
   - ~/.edgerc
3. Execute phase-3 plan:
   - ./apply_phase3.sh plan
4. Review plan for expected IAM/AppSec create actions only.
5. Execute phase-3 apply:
   - ./apply_phase3.sh apply
6. Run full validation:
   - terraform validate
   - terraform plan

## B) Optional hardening follow-ups
1. Move secrets out of terraform.tfvars into environment/secret manager workflow.
2. Rotate any keys/tokens that were exposed during implementation sessions.
3. Add CI checks for:
   - terraform fmt -check
   - terraform validate
   - terraform plan (read-only gate)
4. Add a short cutover checklist for Akamai staging-to-production policy activation.

## 8. Server-Side Branch-Specific Configuration Deployment
### Completed
- Deployed per-branch environment files to deployment host (172.232.54.62)
- Created directory structure: /etc/365db/{booking_client,booking_dashboard,pms_backend}/
- Created 9 total environment files:
  - booking_client: main.env, dev.env, prod.env
  - booking_dashboard: main.env, dev.env, prod.env
  - pms_backend: main.env, dev.env, prod.env
  
### File content deployed
Each service branch file contains:
- **booking_client**: NEXT_PUBLIC_API_BASE_URL (branch-specific), NODE_ENV settings
- **booking_dashboard**: DJANGO_SETTINGS_MODULE (qa/dev/prod), DEBUG flag, ALLOWED_HOSTS per branch
- **pms_backend**: DJANGO_SETTINGS_MODULE (local/testing/production), DATABASE_URL per branch

### Integration point
- CD workflows now source these files at deployment time via:
  ```bash
  if [ -n "$DEPLOY_REMOTE_SETTINGS_FILE" ] && [ -f "$DEPLOY_REMOTE_SETTINGS_FILE" ]; then
    . "$DEPLOY_REMOTE_SETTINGS_FILE"
  fi
  ```
- GitHub Environments provide per-branch DEPLOY_REMOTE_SETTINGS_FILE path resolution (main/dev/prod)

## 9. Practical Status Summary
- Linode implementation: complete and stable.
- Terraform drift status: clean (no pending changes).
- GitHub CI/CD: fully deployed and operational (all three repos with branch-scoped secrets + environment variables).
- Server-side branch-specific configuration: deployed and verified on 172.232.54.62.
- Akamai implementation: intentionally not applied yet; gated behind explicit phase-3 prerequisites.
- Next blocking dependency: real Akamai IDs and valid ~/.edgerc.
