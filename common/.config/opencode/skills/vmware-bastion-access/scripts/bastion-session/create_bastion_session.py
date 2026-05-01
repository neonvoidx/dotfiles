import argparse
import json
import oci
from datetime import date
import random
import time
import pyperclip
from oci.bastion.models import CreateDynamicPortForwardingSessionTargetResourceDetails, CreatePortForwardingSessionTargetResourceDetails

SESSION_TTL_SECONDS=10800
MAX_RETRY = 3
SLEEP_SECONDS = 5
SEPARATOR = "---------------------"

class InputParams:
    def __init__(self, input_params):
        self.profile = input_params['oci_config']['profile']
        self.region = input_params['oci_config'].get('region')
        
        self.bastion_id = input_params['bastion']['id']
        self.port = input_params['bastion']['port']
        self.session_type = input_params['bastion']['session_type']
        self.ip = input_params['bastion'].get('ip', None)

        self.user_id = input_params['user']['id']
        self.public_key_file = input_params['user']['public_key_file']
        self.private_key_file = input_params['user']['private_key_file']        
        

def load_input(args):
    with open(args.input, "r") as f:
        return json.load(f)
    
def load_input_params():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", default='', help="Input parameters file path")
    args = parser.parse_args()
    input_params = load_input(args)
    return InputParams(input_params)
    
def load_oci_config(profile, region=None):        
    config = oci.config.from_file(profile_name=profile)
    token_file = config['security_token_file']
    with open(token_file, 'r') as f:
        token = f.read()
    private_key = oci.signer.load_private_key_from_file(config['key_file'])
    signer = oci.auth.signers.SecurityTokenSigner(token, private_key)
    cli_config = {'region': region or config['region'], 'tenancy': config['tenancy']}    

    return signer, cli_config
    
    
def get_bastion_client(p:InputParams):    
    signer, cli_config = load_oci_config(p.profile, p.region)    
    return oci.bastion.BastionClient(cli_config, signer=signer)

def get_target_resource_details(p:InputParams):
    if p.session_type == CreateDynamicPortForwardingSessionTargetResourceDetails.SESSION_TYPE_DYNAMIC_PORT_FORWARDING:
        return CreateDynamicPortForwardingSessionTargetResourceDetails(
            session_type=CreateDynamicPortForwardingSessionTargetResourceDetails.SESSION_TYPE_DYNAMIC_PORT_FORWARDING)
    
    if p.session_type == CreatePortForwardingSessionTargetResourceDetails.SESSION_TYPE_PORT_FORWARDING:
        return CreatePortForwardingSessionTargetResourceDetails(
            session_type=CreateDynamicPortForwardingSessionTargetResourceDetails.SESSION_TYPE_PORT_FORWARDING,
             target_resource_private_ip_address=p.ip
        )
    
    raise ValueError("Could not get target resource details.")

def create_bastion_session(p:InputParams, display_name):
    public_key_content = ''
    target_resource_details = get_target_resource_details(p)

    with open(p.public_key_file, "r") as f:
        public_key_content = f.read()

    create_session_response = bastion_client.create_session(
        create_session_details=oci.bastion.models.CreateSessionDetails(
            bastion_id=p.bastion_id,
            display_name=display_name,
            key_details=oci.bastion.models.PublicKeyDetails(public_key_content=public_key_content),
            key_type="PUB",
            session_ttl_in_seconds=SESSION_TTL_SECONDS,
            target_resource_details=target_resource_details
        )
    )

    return create_session_response.data

def get_session(session_id):
    get_session_response = bastion_client.get_session(
            session_id=session_id)
    return get_session_response.data

def create_bastion_session_wait_for_active(p:InputParams, display_name):
    bastion_session = create_bastion_session(p, display_name)
    session_id = bastion_session.id
    lifecycle_state = bastion_session.lifecycle_state    
    current_try = 0
    session = bastion_session
    while lifecycle_state != "ACTIVE" and current_try < MAX_RETRY:
        print("Wating for sesion status to become ACTIVE")
        time.sleep(SLEEP_SECONDS)
        session = get_session(session_id)        
        lifecycle_state = session.lifecycle_state
        current_try += 1

    return session

def get_dynamic_port_forward_command(p:InputParams, bastion_session):
    ssh_metadata = bastion_session.ssh_metadata
    command = ssh_metadata['command']
    ssh_with_keep_alive = "ssh -o \"ServerAliveInterval 60\" "

    return command.replace("ssh ", ssh_with_keep_alive) \
        .replace("<privateKey>", p.private_key_file) \
        .replace("<localPort>", p.port)

def generate_display_name(p:InputParams):
    return f'Session-{date.today().strftime("%Y%m%d")}-{random.randint(1, 100)}-{p.user_id}'

p = load_input_params()
display_name = generate_display_name(p)

bastion_client = get_bastion_client(p)
bastion_session = create_bastion_session_wait_for_active(p, display_name)
print(f'Created bastion session: {display_name}: {bastion_session.id}')

command = get_dynamic_port_forward_command(p, bastion_session)
pyperclip.copy(command)
print(SEPARATOR)
print(f'SSH command of session {display_name} (also copied to your clipboard):')
print(SEPARATOR)
print(command)
print(SEPARATOR)
