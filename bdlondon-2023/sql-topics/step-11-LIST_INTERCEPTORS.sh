curl \
    --silent \
    --request GET "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptors" \
    --user "admin:conduktor" \
    --header 'Content-Type: application/json' | jq
