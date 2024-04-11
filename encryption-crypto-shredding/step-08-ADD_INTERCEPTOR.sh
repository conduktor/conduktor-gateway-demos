#!/bin/bash
cat step-08-crypto-shredding-encrypt.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-encrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-crypto-shredding-encrypt.json | jq
