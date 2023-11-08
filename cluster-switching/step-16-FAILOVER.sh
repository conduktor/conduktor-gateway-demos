curl \
  --request POST 'http://localhost:8888/admin/pclusters/v1/pcluster/main/switch?to=failover' \
  --user 'admin:conduktor' \
  --silent | jq
