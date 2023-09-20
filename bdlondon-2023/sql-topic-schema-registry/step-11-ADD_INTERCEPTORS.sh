curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/red-cars" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.VirtualSqlTopicPlugin","priority":100,"config":{"virtualTopic":"red-cars","statement":"SELECT * FROM cars WHERE color = 'red'","schemaRegistryConfig":{"host":"http://schema-registry:8081"}}}' | jq
