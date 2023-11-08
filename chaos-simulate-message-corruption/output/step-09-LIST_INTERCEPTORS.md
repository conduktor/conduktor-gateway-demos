
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
      "name": "simulate-massage-corruption",
      "pluginClass": "io.conduktor.gateway.interceptor.chaos.ProduceSimulateMessageCorruptionPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "topic": "with-random-bytes",
        "sizeInBytes": 10,
        "rateInPercent": 100
      }
    }
  ]
}

```

</details>
      
