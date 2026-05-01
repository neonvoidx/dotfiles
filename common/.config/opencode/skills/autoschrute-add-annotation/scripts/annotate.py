import argparse
import os
import re
from devops_grafana_client import GrafanaClient

def extract_token_from_file(filepath):
    with open(filepath) as file:
        line = file.readline()
        # Use regular expression to extract the token between quotes
        match = re.search(r'OP_TOKEN="([^"]+)"', line)
        if match:
            return match.group(1)
        else:
            raise ValueError("Token not found or invalid file format.")

def get_token():
    token_file = f"{os.path.expanduser('~')}/devops_mcp.env"
    print(f"Reading token from file {token_file}")
    if 'TOKEN_FILE' in os.environ:
        token_file = os.environ['TOKEN_FILE']
    try:
        return extract_token_from_file(token_file)
    except Exception as e:
        print(f"Error reading token file {token_file}: {e}")
        exit(1)

def main():
    parser = argparse.ArgumentParser(description="Sample script taking region and token")
    parser.add_argument('--region', required=True, help='OCI region')
    parser.add_argument('--dashboardUid', required=True, help='Dashboard UID')
    parser.add_argument('--startTimeInMs', required=True, help='incident start time in ms'),
    parser.add_argument('--endTimeInMs', required=True, help='incident end time in ms'),
    parser.add_argument('--text', required=True, help='annotation text')
    parser.add_argument('--panelId', required=True, help='panel ID')
    args = parser.parse_args()

    client = GrafanaClient(get_token())

    try:
        middle_time = (int(args.startTimeInMs) + int(args.endTimeInMs)) // 2
        print(f"Annotating time {middle_time}")
        dashboard = client.get_grafana_dashboard(args.dashboardUid)
        dashboard_id = dashboard["dashboard"]["id"]
        response = client.write_grafana_annotation(
            dashboard_id=dashboard_id,
            time=middle_time,
            text=args.text, tags=["Autoschrute annotated", args.region],
            panel_id=int(args.panelId),
            time_end=None)
        print("Success!!")
    except Exception as e:
        print(f"ERROR: failed to annotate grafana panel {e}")
        exit(1)

if __name__ == "__main__":
    main()