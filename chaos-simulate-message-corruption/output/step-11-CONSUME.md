
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic with-random-bytes \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
jq: parse error: Invalid numeric literal at line 2, column 0
{
  "message": "hello world"
}
[2024-01-22 18:09:40,918] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

```

</details>
      
