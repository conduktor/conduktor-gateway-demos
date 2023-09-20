curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-alter-topic" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin","priority":100,"config":{"retentionMs":{"min":86400000,"max":432000000}}}' | jq
