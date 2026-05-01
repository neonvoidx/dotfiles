---
name: find-5xx-times
description: Use when you need to scan a date range for elevated 5xx windows for a specific region, T2 project, and fleet using the packaged parser script.
metadata:
  owner: ocm
  last_updated: "2026-03-03"
  harnesses: [cline, claudecode, opencode, codex]
---

# find-5xx-times

Run `parser.py` to identify time windows with elevated external 5xx counts for a given T2 project/fleet in a region.

Use this when you need a quick, repeatable way to answer:

- “Which 5-hour windows had elevated 5xx?”
- "What are the elevated 5xx windows for a given region, T2 project, fleet, and date range?"

## Entrypoint

- Primary script: `./scripts/parser.py`
- Dependency file: `scripts/requirements.txt`

## Usage

- You have: **region**, **T2 project**, **fleet**, and a **date range**.
- You want a coarse-grained scan for elevated 5xx windows (default 5-hour windowing).
## Script location

All required scripts for this skill are located in the skill's scripts directory.

## Prerequisites

1) **Python 3** available on PATH.

2) Python dependency **`requests`** available.

3) An OP token file at:

`{env:HOME}/devops_token.env`

The first line must be:

```bash
OP_TOKEN="<your_token>"
```

### Auth bridge: DOPE env file → parser token file

The parser expects a dedicated token file (`TOKEN_FILE` env var) whose first line is `OP_TOKEN="<token>"`. The DOPE MCP server env file contains additional variables and is not directly compatible.

If the operator's DOPE env file is available, extract the token:
```bash
grep '^OP_TOKEN=' <dope-env-file> > /tmp/parser_token.env
TOKEN_FILE=/tmp/parser_token.env python3 ./scripts/parser.py ...
```

Ask the operator for their DOPE env file path if `{env:HOME}/devops_token.env` does not exist. Do not assume a fixed location — it varies by setup.

## Inputs

Required flags for `parser.py`:

- `--region` (OCI region identifier used by Grafana T2 API path)
- `--project` (T2 project name)
- `--fleet` (T2 fleet name)
- `--start` (YYYY-MM-DD)
- `--end` (YYYY-MM-DD)

Do not commit or paste tokens into repo files.

## Procedure

### 1) (Optional) Create a virtualenv and install dependencies

If dependencies are not installed locally:

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r scripts/requirements.txt
```

### 2) Run parser.py

Run the primary entrypoint script: `./scripts/parser.py`.

```bash
TOKEN_FILE={env:HOME}/devops_token.env \
python3 ./scripts/parser.py \
  --region us-ashburn-1 \
  --project marketplace \
  --fleet marketplace-consumer-service-prod \
  --start 2026-03-01 \
  --end 2026-03-03
```

Notes:
- Ensure to add TOKEN_FILE environment variable when running the script, e.g. `TOKEN_FILE={env:HOME}/devops_token.env python3 parser.py ...`
- The script reads the OP token from `{env:HOME}/devops_token.env`.
- The script currently uses a fixed MQL query and a fixed 5-hour scan window.
- If the script returns an empty list (`[]`), it means no windows exceeded the current hard-coded threshold for "elevated 5xx". Don't try to adjust the threshold on your own. Indicate to the caller that there were no elevated 5xx windows based on the current threshold.

## Verify

Pass criteria:

- You see a line like:

  - `determining incidents between <start> to <end>`

- The script prints an array of time ranges at the end, e.g.:

  - `time periods at which we are seeing elevated 5xx are [("2026-03-01 00:00:00", "2026-03-01 05:00:00"), ...]`

If the output is an empty list (`[]`), it means no windows exceeded the current hard-coded threshold.

## Failure modes

If you see errors related to authentication/permissions (e.g. public key invalid, or HTTP 401/403 from Grafana/T2 API), **stop execution immediately**. Renew your operator token and then re-run.

### Token file missing / invalid

Symptoms:

- `Error reading token file ...`
- `ERROR: Token not found or invalid file format.`

Fix:

- Ensure `TOKEN_FILE={env:HOME}/devops_token.env` is set when
- Ensure `{env:HOME}/devops_token.env` exists.
- Ensure the first line matches: `OP_TOKEN="..."`.

### Auth / permission issues (401/403)

Symptoms:

- HTTP 401/403 from Grafana/T2 query endpoint

Fix:

- **Stop the run** (do not continue scanning more windows).
- Renew your OP token.
- Re-run the command.

### Missing dependencies

Symptoms:

Errors such as
- `ModuleNotFoundError: No module named 'requests'`

Fix:

- Create a venv and `python3 -m pip install -r scripts/requirements.txt` (see Procedure step 1).

### Invalid date format

Symptoms:

- `ERROR: Make sure start and end dates are of the format YYYY-MM-DD`
