
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic concentrated-topic-with-100-partitions \
    --from-beginning \
    --timeout-ms 10000 \
    --property print.headers=true 
NO_HEADERS	{"msg":"hello world"}
[2024-01-23 03:08:25,902] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

```

</details>
      
