#!/bin/bash
cat step-08-acl.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/aclCluster/interceptor/acl" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-acl.json | jq
