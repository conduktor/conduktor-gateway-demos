
<details>
<summary>Command output</summary>

```sh

cat step-09-encrypt-on-consume.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.FetchEncryptPlugin",
  "priority": 100,
  "config": {
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

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/username/third-party/interceptor/encrypt-on-consume" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-09-encrypt-on-consume.json | jq
{
  "message": "encrypt-on-consume is created"
}

```

</details>
      
