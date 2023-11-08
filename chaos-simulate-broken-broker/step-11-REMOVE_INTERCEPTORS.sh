curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/simulate-broken-brokers" \
    --header 'Content-Type: application/json'
    --user 'admin:conduktor' \
    --silent | jq
