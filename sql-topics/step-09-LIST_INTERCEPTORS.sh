#!/bin/bash
curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/passthrough' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
