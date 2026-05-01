import requests
from requests import Response


class DevOpsMQLClient:
    def __init__(self, token, version, region):
        """
        Set up DevOps client
        :param token: To generate token: export TOKEN="$(ssh operator-access-token.svc.ad1.r1 'generate --mode jwt')"
        :param region: Service region full name.
        :param version: 'v1' or 'v2'
        """
        self.headers = {'Authorization': f'bearer {token}'}
        self.BASE_URL = f'https://grafana.oci.oraclecorp.com/api/t2/{region}/{version}/query'

    def run_query(self, start_time, end_time, query, project, fleet) -> Response:
        """
        run MQL query
        :param query: MQL query like (ListingResource20181001.listListings.Time[1m]>1000).grouping().count().
            See https://docs.cloud.oracle.com/en-us/iaas/Content/Monitoring/Reference/mql.htm
        :param start_time: Start time for query range, e.g., 2020-08-07T20:12:56.315Z
        :param end_time: End time for query range, e.g., 2020-08-07T21:12:56.315Z
        :param project: The project name, default: Marketplace
        :param fleet: The fleet name, default: marketplace-consumer-service-prod
        :return: Response[QueryResult]
        """
        params = {'query': query,
                  'startTime': str(start_time),
                  'endTime': str(end_time),
                  'project': project,
                  'fleet': fleet}
        url = self.BASE_URL
        response = requests.post(url, headers=self.headers, json=params)
        return response
