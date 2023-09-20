curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-produce" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin","priority":100,"config":{"acks":{"value":[-1],"action":"BLOCK"},"compressions":{"value":["NONE","GZIP"],"action":"BLOCK"}}}' | jq
