# Session Types

The source Confluence page distinguishes two bastion session types. Keep them separate.

## `DYNAMIC_PORT_FORWARDING`

Use this for browser-based access to vCenter or vSphere.

- Typical local port in repo examples: `9090`
- Script output looks like:

```bash
ssh -i <private-key> -N -D 127.0.0.1:<local-port> -p 22 <session>@host.bastion.us-ashburn-1.oci.oraclecloud.com
```

- Result: a local SOCKS proxy you can point your browser at

## `PORT_FORWARDING`

Use this for SSH access to the VMware jump host.

- Typical local port in repo examples: `9000`
- Script or console output looks like:

```bash
ssh -i <private-key> -N -L <local-port>:<jump-host-ip>:22 -p 22 <session>@host.bastion.us-ashburn-1.oci.oraclecloud.com
```

- Result: local `localhost:<local-port>` forwards to the jump host's port `22`

Then connect like:

```bash
ssh -i <private-key> -p <local-port> root@localhost
```

## Common mistake

If the operator says "I need to SSH to the jump host" and you create a dynamic port forwarding session, the flow is wrong. Recreate the session as `PORT_FORWARDING`.
