#!/bin/bash
cat step-33-guard-agressive-auto-commit.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-agressive-auto-commit" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-33-guard-agressive-auto-commit.json | jq
