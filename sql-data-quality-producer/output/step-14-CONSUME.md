
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:29093,localhost:29094 \
    --topic dead-letter-topic \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
 | jq
[2024-01-23 02:14:37,292] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "type": "SUV",
  "price": 2000,
  "color": "blue"
}

```

</details>
      
