#!/bin/bash
curl \
  --request POST 'http://localhost:8889/admin/pclusters/v1/pcluster/main/switch?to=failover' \
  --user 'admin:conduktor' \
  --silent | jq
