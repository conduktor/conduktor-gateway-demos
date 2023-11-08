
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 18:31:46,056] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "********",
  "visa": "#abXXXX",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "********",
  "visa": "#88899XXXX",
  "address": "Dubai, UAE"
}

```

</details>
      
