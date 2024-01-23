
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers \
    --from-beginning \
    --timeout-ms 10000 \
    --property print.headers=true 
NO_HEADERS	{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}
NO_HEADERS	{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ;","address":"Dubai, UAE"}
[2024-01-22 23:09:33,086] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages

```

</details>
      
