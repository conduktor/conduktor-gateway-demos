cat step-08-mapping.json | jq

curl \
    --request POST 'http://localhost:8888/admin/vclusters/v1/vcluster/teamA/topics/concentrated-.%2A' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data "@step-08-mapping.json" | jq
