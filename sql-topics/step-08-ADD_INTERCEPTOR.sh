#!/bin/bash
cat step-08-red-cars.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/passthrough/interceptor/red-cars" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-red-cars.json | jq
