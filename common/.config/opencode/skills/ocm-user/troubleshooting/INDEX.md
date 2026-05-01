# Troubleshooting (starter)

## First checks
- Compartments exist: `Migration` and `MigrationSecrets` under your selected root.
- IAM/dynamic groups/policies were created by the prerequisites stack (or already exist).
- OCI session/auth is valid for whichever tool you’re using (console vs CLI vs script).

## Script-driven troubleshooting
- Use `find_asset` to locate assets across compartments.
