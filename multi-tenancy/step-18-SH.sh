#!/bin/bash
curl \
  --silent \
  --request POST localhost:8888/admin/vclusters/v1/vcluster/london/topics/existingLondonTopic \
  --user 'admin:conduktor' \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "physicalTopicName": "existingLondonTopic",
      "readOnly": false,
      "type": "alias"
    }' | jq