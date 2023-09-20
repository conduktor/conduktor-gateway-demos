curl \
    --silent \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/remove-headers" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' | jq
