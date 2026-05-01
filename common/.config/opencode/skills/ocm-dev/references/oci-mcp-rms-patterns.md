---
name: oci-mcp-rms-patterns
description: Working parameter patterns for OCI RMS operations via oci-mcp invoke_oci_api
type: reference
---

## create_job (Plan)

```json
{
  "client_fqn": "oci.resource_manager.ResourceManagerClient",
  "operation": "create_job",
  "params": {
    "create_job_details": {
      "stack_id": "<stack_ocid>",
      "job_operation_details": {
        "operation": "PLAN"
      }
    }
  }
}
```

## create_job (Destroy, auto-approved)

```json
{
  "client_fqn": "oci.resource_manager.ResourceManagerClient",
  "operation": "create_job",
  "params": {
    "create_job_details": {
      "stack_id": "<stack_ocid>",
      "job_operation_details": {
        "operation": "DESTROY",
        "executionPlanStrategy": "AUTO_APPROVED"
      }
    }
  }
}
```

Note: `executionPlanStrategy` must be camelCase, not snake_case. The SDK model auto-converts but oci-mcp passes params directly.

## OCI CLI: create_job (Plan)

```bash
oci resource-manager job create --auth security_token \
  --stack-id "<stack_ocid>" \
  --operation PLAN \
  --query 'data.id' --raw-output
```

## OCI CLI: create_job (Apply from plan)

```bash
oci resource-manager job create --auth security_token \
  --stack-id "<stack_ocid>" \
  --operation APPLY \
  --apply-job-plan-resolution '{"planJobId": "<plan_job_ocid>"}' \
  --query 'data.id' --raw-output
```

Note: `--apply-job-plan-resolution` requires JSON with `planJobId`. Auto-approved apply without a plan job was not successfully achieved via CLI — use the OCI Console for that case.

## OCI CLI: job status + logs

```bash
oci resource-manager job get --auth security_token \
  --job-id "<job_ocid>" \
  --query 'data.{"state":"lifecycle-state","finished":"time-finished"}'

oci resource-manager job get-job-logs-content --auth security_token \
  --job-id "<job_ocid>" \
  --raw-output | tail -30
```

## OCI CLI: create stack from zip

```bash
oci resource-manager stack create --auth security_token \
  --compartment-id "<compartment_ocid>" \
  --display-name "<name>" \
  --config-source "<path_to_zip>" \
  --terraform-version "1.5.x" \
  --variables '{"compartment_ocid": "...", "tenancy_ocid": "...", "region": "..."}' \
  --query 'data.id' --raw-output
```

## KMS vault client FQN

`oci.key_management.KmsVaultClient` (not `oci.kms_vault.KmsVaultClient`)

## KMS management client

`oci.key_management.KmsManagementClient` — requires the vault's `management_endpoint` as the service endpoint. Pass via `endpoint` parameter if oci-mcp supports it.
