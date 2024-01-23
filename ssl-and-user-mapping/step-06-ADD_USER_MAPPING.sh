cat step-06-user-mapping.json | jq

curl \
    --request POST 'http://localhost:8888/admin/userMappings/v1' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data "@step-06-user-mapping.json" | jq
