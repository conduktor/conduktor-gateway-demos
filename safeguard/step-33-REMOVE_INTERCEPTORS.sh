curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection" \
    --header 'Content-Type: application/json'
    --user 'admin:conduktor' \
    --silent | jq
