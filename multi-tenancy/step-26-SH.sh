curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/admin/vclusters/v1/vcluster/paris/topics/existingSharedTopic \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "physicalTopicName": "existingSharedTopic",
    "readOnly": false,
    "concentrated": false
  }' | jq