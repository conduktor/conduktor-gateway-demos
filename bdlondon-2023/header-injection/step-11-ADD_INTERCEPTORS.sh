curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/remove-headers" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.safeguard.MessageHeaderRemovalPlugin","priority":100,"config":{"headerKeyRegex":"X-MY-.*"}}' | jq
