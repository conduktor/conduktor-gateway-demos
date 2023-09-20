curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/encrypt" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.EncryptPlugin","priority":100,"config":{"fields":[{"fieldName":"password","keySecretId":"password-secret","algorithm":{"type":"AES_GCM","kms":"IN_MEMORY"}},{"fieldName":"visa","keySecretId":"visa-secret","algorithm":{"type":"AES_GCM","kms":"IN_MEMORY"}}]}}' | jq
