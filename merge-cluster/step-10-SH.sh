#!/bin/bash
curl \
  --silent \
  --request POST localhost:8888/internal/alias-topic/teamA/us_cars \
  --user 'admin:conduktor' \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "clusterId": "cluster1",
      "physicalTopicName": "cars"
    }' | jq