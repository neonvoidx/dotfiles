# Create Bastion Sessions

## Overview
This script enables a simple way of creating bastion sessions. Primarily aimed at Bastions for the VMWare Labs - however can be used with any OCI bastion.

## Prerequisites
Before running the script, ensure you have the following:
- Python 3.x installed
- Python `pip` installed
- OCI CLI configuration set up with necessary credentials using (region/profile can be changed as required) -

     `oci session authenticate --region us-ashburn-1 --profile-name DEFAULT`

## Setup

Copy the scripts to a local working directory before creating a virtual environment. Do not create `.venv` inside the pack source or synced skill directory — it will flood the aipack ledger with thousands of site-package files.

```bash
cp -r <path-to-this-directory> ~/bastion-session
cd ~/bastion-session
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Usage

- Populate all the required parameters in a `.json` file. Example configuration files for VMWare labs are provided in the `vmware-lab-configs/` folder.
- Run the script with the following command:

    `python3 ./create_bastion_session.py -i <config_json_file_path>`
- The script will create a bastion session, wait for it to become active and copy the ssh command to your clipboard.

Example run:
```
(bastion-session) tarahma@tarahma-mac bastion-session % python3 ./create_bastion_session.py -i ./vmware-lab-configs/ocm-lab06.dynamic-port-forwarding.json
Wating for sesion status to become ACTIVE
Created bastion session: Session-20251106-85-tarahma: ocid1.bastionsession.oc1.iad.amaaaaaag26i5naa2pylzibpmvjo3clqntahvzggwrkkiakjyvchkt5m2r4a
---------------------
SSH command of session Session-20251106-85-tarahma (also copied to your clipboard):
---------------------
ssh -i /Users/tarahma/.ssh/id_rsa -N -D 127.0.0.1:9090 -p 22 ocid1.bastionsession.oc1.iad.amaaaaaag26i5naa2pylzibpmvjo3clqntahvzggwrkkiakjyvchkt5m2r4a@host.bastion.us-ashburn-1.oci.oraclecloud.com
```