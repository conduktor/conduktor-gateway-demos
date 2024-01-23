
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 23:59:29,738] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "name": "eu_cars_record"
}

```

</details>
      
