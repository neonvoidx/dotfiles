# Documentation for Grafana HTTP API: https://grafana.com/docs/grafana/latest/developers/http_api/
import requests

GRAFANA_URL = "https://grafana.oci.oraclecorp.com"

class GrafanaClient:
    def __init__(self, token):
        self.token = token

    def _headers(self):
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
        }

    def do_get(self, api_path: str, params: dict = {}):
        """
        Perform a GET request to the specified Grafana API path.
        :param api_path: The API path to call (relative to GRAFANA_URL).
        :param params: Query parameters for the request.
        :return: The JSON response from the API.
        """
        url = f"{GRAFANA_URL}/{api_path}"
        response = requests.get(url, headers=self._headers(), params=params, timeout=10)
        response.raise_for_status()
        return response.json()

    def do_post(self, api_path: str, body: dict, params: dict = None):
        """
        Perform a POST request to the specified Grafana API path.
        :param api_path: The API path to call (relative to GRAFANA_URL).
        :param body: The JSON-serializable body for the request.
        :param params: Query parameters for the request.
        :return: The JSON response from the API if available, otherwise the response object.
        """
        url = f"{GRAFANA_URL}/{api_path}"
        response = requests.post(url, headers=self._headers(), json=body, params=params, timeout=10)
        response.raise_for_status()
        return response.json()

    def search_grafana_dashboards(self, dashboard_name: str, limit: int = 50):
        """
        It returns a list of Grafana dashboards matching a dashboard_name.
        :param dashboard_name: The name or substring to search for in dashboard titles or URIs.
        :param limit: The number of results per page (default is 50).
        :return: A list of dashboard metadata objects.
        """
        if dashboard_name is None or dashboard_name == '':
            raise RuntimeError('you must specify a substring for dashboard_name')

        params = {
            "type": "dash-db", 
            "query": dashboard_name,
            "limit": limit
        }
        return self.do_get("api/search", params)

    def get_grafana_dashboard(self, dashboard_uid: str):
        """
        It returns a Grafana dashboard as JSON
        :param dashboard_uid:
        """
        return self.do_get(f"api/dashboards/uid/{dashboard_uid}")
    
    def get_grafana_annotations(self, dashboard_id: int, from_ts: int, to_ts: int, limit: int = 50):
        """
        Fetch annotations for a given dashboard in a given time range (epoch ms).
        :param dashboard_id: ID of the Grafana dashboard.
        :param from_ts: Start of time range (epoch datetime in milliseconds).
        :param to_ts: End of time range (epoch datetime in milliseconds).
        :param limit: The number of results per page (default is 50).
        :return: A list of annotation objects.
        """

        if from_ts is None or to_ts is None or from_ts > to_ts:
            raise RuntimeError('Time range for annotations is invalid')

        params = {
            "dashboardId": dashboard_id,
            "from": from_ts,
            "to": to_ts,
            "limit": limit
        }
        return self.do_get("api/annotations", params)
    
    def write_grafana_annotation(self, dashboard_id: int, time: int, time_end: int, text: str, tags: list = [], panel_id: int = 0):
        """
        Create an annotation on a dashboard at a specific time (epoch ms).
        :param dashboard_id: ID of the dashboard to annotate.
        :param time: Start timestamp for the annotation (epoch datetime in milliseconds).
        :param time_end: End timestamp for the annotation (epoch datetime in milliseconds), optional.
        :param text: Text content of the annotation.
        :param tags: List of tags for the annotation, optional.
        :param panel_id: ID of the panel to annotate, defaults to 0 for dashboard-level annotation.
        :return: Response from the API.
        """
        if time is None:
            raise RuntimeError('Time for the annotation cannot be None')

        if time_end is not None and time > time_end:
            raise RuntimeError('Time range for the annotation is invalid')

        if text is None or text == '':
            raise RuntimeError('Text cant be an empty value')

        payload = {
            "dashboardId": dashboard_id,
            "isRegion": False,
            "panelId": panel_id,
            "time": time,
            "text": text,
            "tags": tags
        }
        if time_end is not None:
            payload["timeEnd"] = time_end

        return self.do_post("api/annotations", body=payload)