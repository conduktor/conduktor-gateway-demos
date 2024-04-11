#!/bin/bash
cat step-14-guard-on-alter-topic.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-alter-topic" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-14-guard-on-alter-topic.json | jq
