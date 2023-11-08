
<details>
<summary>Command output</summary>

```sh

echo '{"msg":"hello world"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users
[2024-01-23 00:41:22,904] ERROR Error when sending message to topic users with key: null, value: 21 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Topic 'users' with schemaId is required.

```

</details>
      
