cat step-06-mapping.json | jq

curl \
    --request POST 'http://localhost:8888/admin/vclusters/v1/vcluster/teamA/topics/.%2A' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data "@step-06-mapping.json" | jq
