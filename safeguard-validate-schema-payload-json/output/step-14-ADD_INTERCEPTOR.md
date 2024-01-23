
<details>
<summary>Command output</summary>

```sh

cat step-14-guard-schema-payload-validate.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin",
  "priority": 100,
  "config": {
    "schemaRegistryConfig": {
      "host": "http://schema-registry:8081"
    },
    "topic": "topic-.*",
    "schemaIdRequired": true,
    "validateSchema": true,
    "action": "BLOCK"
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-schema-payload-validate" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-14-guard-schema-payload-validate.json | jq
{
  "message": "guard-schema-payload-validate is created"
}

```

</details>
      
