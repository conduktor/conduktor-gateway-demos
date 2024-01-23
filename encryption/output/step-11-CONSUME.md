
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
[2024-01-22 18:37:40,425] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "AAAABQFEUDYbjnAKxafkUNmVjHVaWIuoC45hXMu5cf2Z9XTZ7ByeemIlrX7OQA+b5yXekCY=",
  "visa": "AAAABQH5LqEfQQmnr655KNlOvcDKZEms2oF+tcQHk5Xzf3k0gH6ss+uBiAOtDT6pQMKi",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "AAAABQFEUDYbKCJjVZdPsdWAsq+XyYO3XfOHOoR7OT1EkkVp8PEUBo1oG3/bedfCiUO6qw==",
  "visa": "AAAABQH5LqEfGBt6Urj4a6TK4mSCRWNUPu6Sgh+pUXNyTdShggg+w74mDCLwYcgIiMe+2wMR",
  "address": "Dubai, UAE"
}

```

</details>
      
