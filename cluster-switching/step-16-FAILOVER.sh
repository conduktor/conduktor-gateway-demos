curl \
  --silent \
  --user "admin:conduktor" \
  --request POST 'http://localhost:8889/admin/pclusters/v1/pcluster/main/switch?to=failover' | jq
