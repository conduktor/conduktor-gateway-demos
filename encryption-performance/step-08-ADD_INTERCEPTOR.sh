#!/bin/bash
cat step-08-decrypt.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/decrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-decrypt.json | jq
