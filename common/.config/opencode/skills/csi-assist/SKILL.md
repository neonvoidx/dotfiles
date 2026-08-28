### Security Central Assist plugin

This installs `csis-local-scan` and the workflow-level pre-PR validator. It does not install `csis-pr-gate`.

```bash
codex plugin marketplace add ssh://git@bitbucket.oci.oraclecorp.com:7999/csis/oracle-security-ai.git --ref master
codex plugin add security-central-assist@oracle-security
```

Restart Codex, then verify with:

```text
@security-central-assist scan my project
```

Source: [CSIS installation guide](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20552488625).

### Product Catalog `csis-pr-gate`

This installs the actual agent hook as part of the larger, Product Catalog-specific `opc-ai-pack`:

```bash
aipack pack install opc-ai-pack --add
aipack sync --dry-run --harness codex
aipack sync --harness codex
```

Source: [Product Catalog SCM repository](https://devops.oci.oraclecorp.com/devops-coderepository/namespaces/axuxirvibvvo/projects/product_catalog/repositories/product-catalog-ai-tools/files?folderPath=opc-ai-pack%2Fhooks%2Fcsis-pr-gate&refName=refs%2Fheads%2Fmain&_ctx=us-phoenix-1%2Cdevops_scm_central).

For a Product Catalog engineer who wants enforcement, the complete setup is both command blocks: the CSIS plugin provides the scanner; `opc-ai-pack` provides the PR gate.

For non-Codex harnesses, the scanner has an AIPack bridge:

```bash
aipack pack install csis-ai-skills --add
aipack sync --dry-run
aipack sync
```

That bridge contains the scanning skills but not `csis-pr-gate`.
[3:41 PM]Exactly. Install the pack as quiet, then explicitly include only the hook:

```bash
aipack pack install opc-ai-pack --add --quiet
aipack profile include csis-pr-gate --pack opc-ai-pack --kind hook

aipack sync --dry-run --harness codex
aipack sync --harness codex
```

This downloads the complete pack to disk, but only `csis-pr-gate` is activated and synced. Its skills, MCP server, settings, and other content remain inactive.

The hook still expects `csis-local-scan`, supplied by the [Security Central Assist plugin](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20552488625). Restart Codex after syncing the hook.
