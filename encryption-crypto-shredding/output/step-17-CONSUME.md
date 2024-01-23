
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 18:44:53,430] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "AAAABQAAAEl2YXVsdDp2MTo3WlBwbkNvbDV6MldBVU5OOWFCb3hNUEwzdGloaHFvUlZQWEp5QXJLWk45ZEdXRThCcXZZQTlTdk5KL3RlZz09AbeObkx5xHvroJXGN4kDUkOoR2txR+18qvrdx3a05CRLOq0K36nDVMk2YQ==",
  "visa": "AAAABQAAAEl2YXVsdDp2MTo5QUd4aG40cDdlamJ3ZWNicHJwekRGNWR3K1hGNGZYL2ZoY09rQkJLZGp0NVF2WHpsTW1ubzd5aDVTZXpYQT09YQTd/OqhYTbNXyp0FuQu2uVcaBA/ay4d8N6tyfO3ieSKRxrGF+yh40jdGFc=",
  "address": "Dubai, UAE"
}
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
}

```

</details>
      
