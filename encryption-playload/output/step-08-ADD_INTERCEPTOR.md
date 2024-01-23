
<details>
<summary>Command output</summary>

```sh

cat step-08-encrypt-full-payload.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
  "priority": 100,
  "config": {
    "payload": {
      "keySecretId": "full-payload-secret",
      "algorithm": {
        "type": "AES_GCM",
        "kms": "IN_MEMORY"
      }
    }
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/encrypt-full-payload" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-encrypt-full-payload.json | jq
{
  "message": "encrypt-full-payload is created"
}

```

</details>
      
