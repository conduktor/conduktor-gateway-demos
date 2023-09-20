curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/decrypt" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.DecryptPlugin","priority":100,"config":{"topic":"customers","schemaRegistryConfig":{"host":"http://schema-registry:8081"}}}' | jq
