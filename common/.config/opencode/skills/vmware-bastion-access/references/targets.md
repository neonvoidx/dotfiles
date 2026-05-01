# VMware Lab Targets

Source of truth for these mappings:

- Confluence page `HOW TO: Access VMware Instances using OCI Bastions (September 2025)`
- page id `17019374756`
- page version `21`
- accessed `2026-03-19`

Use these values when selecting the bastion target and the matching example JSON file. 
If the document has a new page version, stop the process and ask the user to confirm the diff between the current version and the new version. If user says it is valid, update the page version in this document.

## `sddc7` / `ocbdev`

- vCenter URL: `https://vcenter-appliance-sddc70.sddc.iad.oci.oraclecloud.com`
- VMware jump host IP: `10.0.1.122`
- Bastion OCID: `ocid1.bastion.oc1.iad.amaaaaaabkvmyqqabfqgwa6nxos7btni3rh7wk3xqqoftev27qrnykei65ua`
- Dynamic port forwarding example: `scripts/bastion-session/vmware-lab-configs/sddc7.dynamic-port-forwarding.json`
- SSH port forwarding example: `scripts/bastion-session/vmware-lab-configs/sddc7.port-forwarding.json`

## `ocm-lab06` / `ocmdemo`

- vCenter URL: `https://vcenter-ocmlab06.sddc.iad.oci.oraclecloud.com`
- VMware jump host IP: `172.16.2.138`
- Bastion OCID: `ocid1.bastion.oc1.iad.amaaaaaag26i5naawzyb7y6awqfudtwlbeo4mqwquaxn73zrcduwvnvewiwq`
- Dynamic port forwarding example: `scripts/bastion-session/vmware-lab-configs/ocm-lab06.dynamic-port-forwarding.json`
- SSH port forwarding example: `scripts/bastion-session/vmware-lab-configs/ocm-lab06.port-forwarding.json`

## Selection rule

- Use the `dynamic-port-forwarding` example when the goal is browser access to vCenter or vSphere through a local SOCKS proxy.
- Use the `port-forwarding` example when the goal is SSH access to the VMware jump host.

If the bastion OCID, jump-host IP, or vCenter URL drift from reality, update this file and the example JSON files together.
