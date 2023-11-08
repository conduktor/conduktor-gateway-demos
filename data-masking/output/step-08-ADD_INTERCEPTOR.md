
<details>
<summary>Command output</summary>

```sh

cat step-08-data-masking.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.FieldLevelDataMaskingPlugin",
  "priority": 100,
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

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/data-masking" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-data-masking.json | jq
{
  "message": "data-masking is created"
}

```

</details>
      
