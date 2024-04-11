#!/bin/bash
cat step-08-concentration-rule.json | jq

curl \
    --request POST 'http://localhost:8888/admin/vclusters/v1/vcluster/teamA/concentration-rules' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data "@step-08-concentration-rule.json" | jq
