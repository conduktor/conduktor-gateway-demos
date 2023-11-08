
<details>
<summary>Command output</summary>

```sh

cat step-08-crypto-shredding-encrypt.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
  "priority": 100,
  "config": {
    "topic": "customers-shredding",
    "kmsConfig": {
      "vault": {
        "uri": "http://vault:8200",
        "token": "vault-plaintext-root-token",
        "version": 1
      }
    },
    "fields": [
      {
        "fieldName": "password",
        "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
        "algorithm": {
          "type": "AES_GCM",
          "kms": "VAULT"
        }
      },
      {
        "fieldName": "visa",
        "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
        "algorithm": {
          "type": "AES_GCM",
          "kms": "VAULT"
        }
      }
    ]
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-encrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-crypto-shredding-encrypt.json | jq
{
  "message": "crypto-shredding-encrypt is created"
}

```

</details>
      
