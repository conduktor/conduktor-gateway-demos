curl \
    -u "admin:conduktor" \
    --request GET "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptors" \
    --header 'Content-Type: application/json' | jq
