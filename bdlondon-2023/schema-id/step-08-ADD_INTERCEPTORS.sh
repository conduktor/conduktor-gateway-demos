curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/schema-id" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.safeguard.TopicRequiredSchemaIdPolicyPlugin","priority":100,"config":{"topic":"users","schemaIdRequired":true}}' | jq
