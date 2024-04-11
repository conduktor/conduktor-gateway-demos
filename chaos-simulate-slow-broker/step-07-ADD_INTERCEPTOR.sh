#!/bin/bash
cat step-07-simulate-slow-broker.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/simulate-slow-broker" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-07-simulate-slow-broker.json | jq
