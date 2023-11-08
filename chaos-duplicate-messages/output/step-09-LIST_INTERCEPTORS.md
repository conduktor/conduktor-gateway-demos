
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
      "name": "duplicate-messages",
      "pluginClass": "io.conduktor.gateway.interceptor.chaos.DuplicateMessagesPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "rateInPercent": 100,
        "topic": "topic-duplicate",
        "target": "PRODUCE"
      }
    }
  ]
}

```

</details>
      
