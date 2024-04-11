#!/bin/bash
curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/remove-headers" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
