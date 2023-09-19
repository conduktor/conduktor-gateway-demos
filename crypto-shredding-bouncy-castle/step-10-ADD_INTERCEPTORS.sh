curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-encrypt" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.EncryptPlugin","priority":100,"config":{"topic":"customers-shredding","kmsConfig":{"vault":{"uri":"http://vault:8200","token":"vault-plaintext-root-token","version":1}},"fields":[{"fieldName":"password","keySecretId":"vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}","algorithm":{"type":"AES_GCM","kms":"VAULT"}},{"fieldName":"visa","keySecretId":"vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}","algorithm":{"type":"AES_GCM","kms":"VAULT"}}]}}' | jq
