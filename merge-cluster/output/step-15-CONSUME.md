
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic us_cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 23:59:17,957] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "name": "us_cars_record"
}

```

</details>
      
