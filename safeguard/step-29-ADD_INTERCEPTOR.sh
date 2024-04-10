#!/bin/bash
cat step-29-guard-limit-connection.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-29-guard-limit-connection.json | jq
