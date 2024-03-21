#!/bin/bash
cat step-08-field level encryption for header.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/field level encryption for header" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-field level encryption for header.json | jq
