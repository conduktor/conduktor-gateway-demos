#!/bin/bash
curl \
  --silent \
  --request POST localhost:8888/internal/alias-topic/teamA/eu_cars \
  --user 'admin:conduktor' \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "clusterId": "main",
      "physicalTopicName": "cars"
    }' | jq