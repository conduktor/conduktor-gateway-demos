curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-decrypt" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.DecryptPlugin","priority":100,"config":{"topic":"customers-shredding","kmsConfig":{"vault":{"uri":"http://vault:8200","token":"vault-plaintext-root-token","version":1}}}}' | jq
