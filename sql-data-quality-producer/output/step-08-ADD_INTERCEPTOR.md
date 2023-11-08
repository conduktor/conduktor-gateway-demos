
<details>
<summary>Command output</summary>

```sh

cat step-08-myDataQualityProducer.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.DataQualityProducerPlugin",
  "priority": 100,
  "config": {
    "statement": "SELECT * FROM cars WHERE color = 'red' and record.key.year > 2020",
    "action": "BLOCK_WHOLE_BATCH",
    "deadLetterTopic": "dead-letter-topic"
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/myDataQualityProducer" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-myDataQualityProducer.json | jq
{
  "message": "myDataQualityProducer is created"
}

```

</details>
      
