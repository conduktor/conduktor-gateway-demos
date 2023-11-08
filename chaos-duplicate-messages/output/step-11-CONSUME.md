
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-duplicate \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 17:36:01,124] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "message": "hello world"
}
{
  "message": "hello world"
}

```

</details>
      
