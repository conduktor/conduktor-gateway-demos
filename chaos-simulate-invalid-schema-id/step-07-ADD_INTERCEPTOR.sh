#!/bin/bash
cat step-07-simulate-invalid-schema-id.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/simulate-invalid-schema-id" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-07-simulate-invalid-schema-id.json | jq
