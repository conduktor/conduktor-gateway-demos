#!/bin/bash
curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/teamA/username/third-party' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
