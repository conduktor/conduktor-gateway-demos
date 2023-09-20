curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin","priority":100,"config":{"replicationFactor":{"min":2,"max":2},"numPartition":{"min":1,"max":3}}}' | jq
