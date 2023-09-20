curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/inject-headers" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.DynamicHeaderInjectionPlugin","priority":100,"config":{"headers":{"X-MY-KEY":"my own value","X-USER":"{{user}}","X-INTERPOLATED":"User {{user}} via ip {{userIp}}"}}}' | jq
