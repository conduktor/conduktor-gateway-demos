#!/bin/bash
cat step-09-full payload level encryption.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/full payload level encryption" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-09-full payload level encryption.json | jq
