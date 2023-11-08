
<details>
<summary>Command output</summary>

```sh

cat step-11-guard-on-create-topic.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin",
  "priority": 100,
  "config": {
    "replicationFactor": {
      "min": 2,
      "max": 2
    },
    "numPartition": {
      "min": 1,
      "max": 3
    }
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-11-guard-on-create-topic.json | jq
{
  "message": "guard-on-create-topic is created"
}

```

</details>
      
