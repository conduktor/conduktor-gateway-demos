
<details>
<summary>Command output</summary>

```sh

curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/teamA' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
{
  "interceptors": [
    {
      "name": "encrypt-full-payload",
      "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
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
  ]
}

```

</details>
      
