
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
[2024-01-22 18:51:37,080] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "AAAABQHU3iNQtCsw5zISYuiXBw1ERQyAJAqjFHJl7mOaYvXfACLIQ+72wKoP3KB+ZTP8D4A=",
  "visa": "AAAABQGOj0UnpJiod/350N0XC+9EtX0YxLuB9xhNemc/eLnj4vHIUfeLHPT3+l/NHaT2",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "AAAABQHU3iNQJN/9kBBvSAUum5Fw4xEW7jHk1y03VwvFMx2lORL6gTTTjsgnmUKBfWBUEw==",
  "visa": "AAAABQGOj0UnIU2qPo0yYkNzuQom3aYN/LG0W23iyQQqRINxHxnAf8clpq50l+5+j6gaKWO2",
  "address": "Dubai, UAE"
}

```

</details>
      