
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
      "name": "data-masking",
      "pluginClass": "io.conduktor.gateway.interceptor.FieldLevelDataMaskingPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "policies": [
          {
            "name": "Mask password",
            "rule": {
              "type": "MASK_ALL"
            },
            "fields": [
              "password"
            ]
          },
          {
            "name": "Mask visa",
            "rule": {
              "type": "MASK_LAST_N",
              "maskingChar": "X",
              "numberOfChars": 4
            },
            "fields": [
              "visa",
              "a.b.c",
              "visa3"
            ]
          }
        ]
      }
    }
  ]
}

```

</details>
      
