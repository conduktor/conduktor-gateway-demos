
<details>
<summary>Command output</summary>

```sh

cat step-21-produce-rate.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin",
  "priority": 100,
  "config": {
    "maximumBytesPerSecond": 1
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-21-produce-rate.json | jq
{
  "message": "produce-rate is created"
}

```

</details>
      
