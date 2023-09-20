curl \
    --silent \
    --user "admin:conduktor" \
    --request POST 'http://localhost:8888/admin/vclusters/v1/vcluster/teamA/topics/concentrated-.%2A' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "physicalTopicName": "hold-many-concentrated-topics",
        "readOnly": false,
        "concentrated": true
    }' | jq
