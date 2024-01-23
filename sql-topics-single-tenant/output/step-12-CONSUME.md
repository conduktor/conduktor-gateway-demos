
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config passthrough-sa.properties \
    --topic red-cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-23 02:49:45,356] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "type": "SUV",
  "money": 55
}

```

</details>
      
