---
name: vmware-bastion-access
description: Use when you need to access OCM VMware lab vCenter endpoints or VMware instances in `ocbdev` or `ocmdemo` through OCI Bastion sessions using the repo-local bastion-session automation.
metadata:
  owner: ocm
  last_updated: "2026-03-19"
  audience: users
  workflow: vmware, bastion, access
---

## Purpose

Provide a repeatable way to:

- open a dynamic port forwarding bastion session for vCenter access
- open an SSH port forwarding bastion session to a VMware jump host
- reach VMware lab instances behind that jump host

## When to use

Use this skill when you need VMware-lab access in `ocbdev` or `ocmdemo`, especially when the OCI Console flow is too manual or you want the repo-local script to generate the SSH command for you.

## When not to use

Do not use this skill when:

- the target is not one of the documented VMware lab bastions in this repo
- you need to mutate OCI resources instead of only creating bastion sessions
- your access depends on a new bastion, jump host, or lab that is not yet captured in `references/targets.md`

## Start here

- `references/targets.md`
- `references/session-types.md`
- `scripts/bastion-session/readme.md`

## Required inputs

Collect these before execution:

- target lab (`sddc7` / `ocbdev` or `ocm-lab06` / `ocmdemo`)
- access mode:
  - `DYNAMIC_PORT_FORWARDING` for browser-based vCenter access
  - `PORT_FORWARDING` for SSH to the VMware jump host
- OCI CLI profile to use
- local path to public/private SSH key pair for the bastion session

If you want to SSH from the jump host into a VMware instance, also collect:

- a VM login key pair
- the target VM IP
- confirmation that your public key is present in the VM's `guestinfo-sshkey`

## Procedure

1. Pick the target entry from `references/targets.md`.

2. Choose the correct session type from `references/session-types.md`.
   - Do not use dynamic port forwarding when your goal is `ssh root@localhost -p <port>`.
   - Do not use SSH port forwarding when your goal is browser access to vCenter.

3. Prepare a local input JSON file for `scripts/bastion-session/create_bastion_session.py`.
   - Start from the matching example under `scripts/bastion-session/vmware-lab-configs/`.
   - Copy it to an untracked local file.
   - Replace the user-specific values:
     - `oci_config.profile`
     - `user.id`
     - `user.public_key_file`
     - `user.private_key_file`
   - Keep the bastion OCID, session type, and jump-host IP aligned with the chosen target.

4. Authenticate OCI CLI if needed:

```bash
oci session authenticate --region us-ashburn-1 --profile-name DEFAULT
```

5. Create the bastion session with the script:

```bash
python3 ./scripts/bastion-session/create_bastion_session.py -i <local-config.json>
```

6. Run the generated SSH command.
   - The script prints it and copies it to your clipboard.
   - Leave that command running for the duration of your access session.

7. If you created an SSH port forwarding session, log into the VMware jump host using the forwarded local port:

```bash
ssh -i <private-key> -p <local-port> root@localhost
```

8. If you need to reach a VMware instance from the jump host:
   - create a directory named with your GUID or username
   - place only the minimum needed VM private key material there
   - verify the target VM has your public key in `guestinfo-sshkey`
   - SSH to the VM by IP from the jump host

## Guardrails

- Treat the example config files under `scripts/bastion-session/vmware-lab-configs/` as examples only. They contain user-specific values and should not be edited in place.
- Do not paste private keys or session tokens into the repo or the AI session.
- Do not assume your key is already present on the VMware jump host. Confirm it before debugging SSH failures.
- Remove temporary private key material from the jump host when you are done.

## Verify

- The bastion session reaches `ACTIVE`.
- The script prints an SSH command and copies it to the clipboard.
- For dynamic port forwarding, the local SOCKS tunnel is listening on the configured port.
- For SSH port forwarding, `ssh -i <private-key> -p <local-port> root@localhost` succeeds.
- If you changed this pack, run `aipack doctor --profile ocm`.

## Failure modes

- **Wrong session type chosen**
  - Recovery: recreate the session with the correct type for the task.

- **Bastion session never becomes active**
  - Recovery: verify OCI CLI auth/profile, the bastion OCID, and your public key file path; then rerun the script.

- **`root@localhost` login fails after port forwarding**
  - Recovery: confirm your public key has been added to `/root/.ssh/authorized_keys` on the target jump host.

- **Cannot SSH from jump host to VMware instance**
  - Recovery: confirm the VM IP, the VM private key, and that the matching public key is present in `guestinfo-sshkey`.
