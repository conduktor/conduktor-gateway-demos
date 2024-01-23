
<details>
<summary>Command output</summary>

```sh

cat step-09-large-messages.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.LargeMessageHandlingPlugin",
  "priority": 100,
  "config": {
    "topic": "large-messages",
    "s3Config": {
      "accessKey": "minio",
      "secretKey": "minio123",
      "bucketName": "bucket",
      "region": "eu-south-1",
      "uri": "http://minio:9000"
    }
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/large-messages" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-09-large-messages.json | jq
{
  "message": "large-messages is created"
}

```

</details>
      
