
<details>
<summary>Command output</summary>

```sh

cat step-08-schema-id.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.TopicRequiredSchemaIdPolicyPlugin",
  "priority": 100,
  "config": {
    "topic": "users",
    "schemaIdRequired": true
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/schema-id" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-schema-id.json | jq
{
  "message": "schema-id is created"
}

```

</details>
      
