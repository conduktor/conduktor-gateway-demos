
<details>
<summary>Command output</summary>

```sh

cat step-08-duplicate-messages.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.chaos.DuplicateMessagesPlugin",
  "priority": 100,
  "config": {
    "rateInPercent": 100,
    "topic": "topic-duplicate",
    "target": "PRODUCE"
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/duplicate-messages" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-duplicate-messages.json | jq
{
  "message": "duplicate-messages is created"
}

```

</details>
      
