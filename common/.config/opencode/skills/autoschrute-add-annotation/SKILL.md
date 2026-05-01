---
name: autoschrute-add-annotation
description: Use when you need to write a Grafana annotation for a confirmed Autoschrute incident window after the mutation gate has been explicitly approved.
metadata:
  owner: ocm
  last_updated: "2026-03-05"
  harnesses: [cline, claudecode, opencode, codex]
---

# autoschrute-add-annotation

Run `scripts/annotate.py` to write a Grafana annotation to a dashboard/panel at the midpoint of an incident time range.

This is typically used by the Autoschrute workflow to mark an incident window on a Grafana panel for later debugging / correlation.

## Entrypoint

- Primary script: `scripts/annotate.py`
- Dependency file: `scripts/requirements.txt`

## Prerequisites

1) **Python 3** available on PATH.

2) Dependencies installed (recommended via venv):

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r ./scripts/requirements.txt
```

3) A valid **operator token** (OP token) file.

By default, the script reads:

- `{env:HOME}/devops_token.env`

You can override the location with the environment variable:

- `TOKEN_FILE=/path/to/file`

The **first line** of the token file must match:

```bash
OP_TOKEN="<your_token>"
```

If the token is invalid/expired (typically shows up as HTTP 401/403), **stop** and refresh your OP token (per your team’s standard process), then re-run.

## Script location

All scripts are located in the skill's `scripts` directory.

## Inputs

All inputs are **required flags** to `annotate.py`:

- `--region` (e.g. `us-ashburn-1`)
- `--dashboardUid` (Grafana dashboard UID)
- `--panelId` (Grafana panel ID on that dashboard)
- `--startTimeInMs` (incident start time, epoch milliseconds)
- `--endTimeInMs` (incident end time, epoch milliseconds)
- `--text` (annotation text to write)

### How the time is chosen

The script writes the annotation at:

```
middle_time = (startTimeInMs + endTimeInMs) // 2
```

## Execution formats

```bash
python3 scripts/annotate.py \
  --region <region> \
  --dashboardUid <dashboard_uid> \
  --panelId <panel_id> \
  --startTimeInMs <epoch_ms> \
  --endTimeInMs <epoch_ms> \
  --text "<annotation text>"
```

If you need a non-default token file:

```bash
TOKEN_FILE=/path/to/devops_token.env \
python3 ./scripts/annotate.py \
  --region <region> \
  --dashboardUid <dashboard_uid> \
  --panelId <panel_id> \
  --startTimeInMs <epoch_ms> \
  --endTimeInMs <epoch_ms> \
  --text "<annotation text>"
```

## Sample command

```bash
TOKEN_FILE={env:HOME}/devops_token.env \
python3 scripts/annotate.py \
  --region us-ashburn-1 \
  --dashboardUid abcDEFgHiJk \
  --panelId 12 \
  --startTimeInMs 1762348800000 \
  --endTimeInMs 1762352400000 \
  --text "Autoschrute: annotated incident INC123456 (midpoint)"
```

## Validation (IMPORTANT)

**Only** consider the output of `annotate.py` itself when deciding whether this skill succeeded.

Ignore other terminal/agent noise (for example: unrelated `ssh-add`, keychain, shell prompts, etc.).

Pass criteria (from `annotate.py` stdout):

- You see:
  - `Reading token from file ...`
  - `Annotating time <some_number>`
  - `Success!!`

Failure criteria (from `annotate.py` stdout/stderr):

- `Error reading token file ...`
- `ERROR: failed to annotate grafana panel ...`

## Notes / Common failure modes

- **Token file missing / wrong format**: ensure the token file exists and its first line is exactly `OP_TOKEN="..."`. Note that the quotes are required around the token value.
- **401/403 or other HTTP errors**: stop and refresh your OP token (per your team’s standard process), then re-run. Also confirm you have access to the target dashboard.
- **Import errors** (e.g. `ModuleNotFoundError`): install dependencies from `scripts/requirements.txt`.
