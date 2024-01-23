
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
[2024-01-22 18:58:10,210] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "AAAABQG4GC0DER/V6ayb0lD6yvJHcy7LxWTV2OKRmz7LAjDaEeJccwYzfcrwldGp3u/9scA=",
  "visa": "AAAABQG58l2Fkec5o6dH4QdcmnrDLU2HLkXsdHrSaTWIBRJ03L80URxzJZN1HlAQI889",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "AAAABQG4GC0Do+gvVRgulCjfX5Adltb5+tI9TAjqtfOJfpZZUQ7Y9K6qIyeGK1hSNPkLWA==",
  "visa": "AAAABQG58l2FjXqVKtdnzlDzxsStpoeedL0eNJOYMVz3f9zAZ+BRKbzUZ+LeQGCHyxVEpb3f",
  "address": "Dubai, UAE"
}

```

</details>
      
