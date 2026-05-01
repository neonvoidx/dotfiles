# Shepherd Limit Review Checklist

For `ocm-shepherd` quota and limit-definition PRs, convention-parity checks are more useful than generic Terraform review.

## Checklist

### 1. Environment-specific `public_name` parity
Check that `public_name` follows the existing environment naming pattern across matching files.

Typical pattern:
- dev: `...-dev`
- rbaas: `...-test`
- prod: no suffix

### 2. Release-flag parity
Compare the new entry's flags with neighboring entries in the same environment file:
- `internalOnly`
- `is_released_to_customer`
- `is_staged`

Differences may be intentional, but they should be treated as explicit review questions, not assumed correct.

### 3. Companion artifact parity
Check whether similar existing limits also have corresponding entries in:
- `limit_values.json`
- `safelimits/*.tpl`
- `limit_overrides.json` when applicable

Absence is not always wrong, but parity with the closest existing limit is a strong review signal.

### 4. Compare against the closest analogous existing limit
Find the nearest existing entry by name/function and use it as the convention baseline.

## Why convention-parity works

This checklist surfaces the real review concerns quickly: misaligned `public_name` across envs, suspicious prod release flags, possible incompleteness versus companion artifacts. That is much more useful than broad Terraform-style review commentary.
