import json
import os
from devops_mql_client import DevOpsMQLClient
import argparse
import re
from datetime import datetime, timedelta


def get_error_count(client, start_time, end_time, query, project, fleet):
    response = client.run_query(start_time, end_time, query, project, fleet)
    print(response.json())
    total = 0
    for entry in response.json():
        for ts_entry in entry["aggregatedDatapoints"]:
            total += ts_entry["value"]
    return total

def merge_intervals(intervals):
    if not intervals:
        return []
    merged = [intervals[0]]

    for current in intervals[1:]:
        prev_start, prev_end = merged[-1]
        curr_start, curr_end = current
        if prev_end == curr_start:
            # Merge by extending the previous interval's end to current's end
            merged[-1] = (prev_start, curr_end)
        else:
            merged.append(current)
    convert_intervals(merged)
    return merged

def convert_intervals(intervals):
    for i in range(len(intervals)):
        intervals[i] = (str(intervals[i][0]), str(intervals[i][1]))

def determine_incidents(client, project, fleet, start_dt, end_dt):
    # Hard coded for now. Need to improve later. Possibly get from case metrics
    # Problem with case metrics is there are a lot of queries. Its hard to determine which one to pick
    query = "ResponseOut_DM.StatusFamily.5XX[5h]{TrafficSource=EXTERNAL}.grouping().count()"
    print(f"determining incidents between {start_dt} to {end_dt}")

    # OCM sets threshold to investigate an incident as 10. Change this accordingly.
    threshold = 10

    # interval with which we through. TODO: configure this via cli input
    window = timedelta(hours=5)

    elevated_periods = []
    current_start = start_dt

    while current_start < end_dt:
        current_end = current_start + window
        error_count = get_error_count(client, current_start, current_end, query, project, fleet)
        if error_count > threshold:
            elevated_periods.append((current_start, current_end))
        current_start = current_end
    
    return merge_intervals(elevated_periods)


def parse_mql(service_name, client):
    # Construct the corresponding case-profile filename
    script_dir = os.path.dirname(os.path.abspath(__file__))

    profile_filename = f"{service_name.replace('-', '')}-profile.json"
    profile_path = os.path.join(f"{script_dir}/case-profiles", profile_filename)

    try:
        with open(profile_path) as file:
            data = json.load(file)
            mql_alias_formulae = data.get('mqlAliasFormulae', [])
            for formula in mql_alias_formulae:
                mql_aliases = formula.get('mqlAliases', [])
                for alias in mql_aliases:
                    if 'mql' in alias and '5XX' in alias['mql']:
                        query = alias['mql']
                        project = alias.get('t2ProjectName', 'marketplace')
                        fleet = alias.get('t2FleetName', 'marketplace-consumer-service-prod')
                        start_time = "-7d"
                        end_time = "now"
                        response = client.run_query(start_time, end_time, query, project, fleet)
                        print(f"MQL Query: {query}")
                        print(f"Response: {response.json()}")
    except FileNotFoundError:
        print(f"File {profile_path} not found.")
    except json.JSONDecodeError:
        print(f"Failed to parse JSON in {profile_path}.")

def extract_token_from_file(filepath):
    with open(filepath) as file:
        line = file.readline()
        # Use regular expression to extract the token between quotes
        match = re.search(r'OP_TOKEN="([^"]+)"', line)
        if match:
            return match.group(1)
        else:
            raise ValueError("ERROR: Token not found or invalid file format.")

def get_token():
    token_file = f"{os.path.expanduser('~')}/devops_mcp.env"
    print(f"Reading token from file {token_file}")
    if 'TOKEN_FILE' in os.environ:
        token_file = os.environ['TOKEN_FILE']
    try:
        return extract_token_from_file(token_file)
    except Exception as e:
        print(f"ERROR: Error reading token file {token_file}: {e}")
        exit(1)

def main():
    parser = argparse.ArgumentParser(description="Sample script taking region and token")
    parser.add_argument('--region', required=True, help='OCI region')
    parser.add_argument('--project', required=True, help='T2 project name')
    parser.add_argument('--fleet', required=True, help='fleet name'),
    parser.add_argument('--start', required=True, help='start date in format YYYY-MM-DD')
    parser.add_argument('--end', required=True, help='end date in format YYYY-MM-DD')
    args = parser.parse_args()
    try:
        start_dt = datetime.strptime(args.start, "%Y-%m-%d")
        end_dt = datetime.strptime(args.end, "%Y-%m-%d")
    except Exception as e:
        print(f"ERROR: Make sure start and end dates are of the format YYYY-MM-DD")
        exit(1)

    version = "v1"  # Default version
    client = DevOpsMQLClient(get_token(), version, args.region)

    incidents = determine_incidents(client, args.project, args.fleet, start_dt, end_dt)
    print(f"time periods at which we are seeing elevated 5xx are {incidents}")

if __name__ == "__main__":
    main()
