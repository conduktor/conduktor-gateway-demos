
<details>
<summary>Command output</summary>

```sh

cat step-11-red-cars.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.VirtualSqlTopicPlugin",
  "priority": 100,
  "config": {
    "virtualTopic": "red-cars",
    "statement": "SELECT * FROM cars WHERE color = 'red'",
    "schemaRegistryConfig": {
      "host": "http://schema-registry:8081"
    }
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/red-cars" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-11-red-cars.json | jq
{
  "message": "red-cars is created"
}

```

</details>
      
