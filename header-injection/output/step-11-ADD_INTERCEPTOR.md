
<details>
<summary>Command output</summary>

```sh

cat step-11-remove-headers.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.MessageHeaderRemovalPlugin",
  "priority": 100,
  "config": {
    "headerKeyRegex": "X-MY-.*"
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/remove-headers" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-11-remove-headers.json | jq
{
  "message": "remove-headers is created"
}

```

</details>
      
