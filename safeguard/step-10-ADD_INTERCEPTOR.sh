#!/bin/bash
cat step-10-guard-on-create-topic.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-10-guard-on-create-topic.json | jq
