
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
      "name": "encrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "externalStorage": true,
        "fields": [
          {
            "fieldName": "password",
            "keySecretId": "password-secret",
            "algorithm": {
              "type": "AES_GCM",
              "kms": "IN_MEMORY"
            }
          },
          {
            "fieldName": "visa",
            "keySecretId": "visa-secret",
            "algorithm": {
              "type": "AES_GCM",
              "kms": "IN_MEMORY"
            }
          }
        ]
      }
    }
  ]
}

```

</details>
      
