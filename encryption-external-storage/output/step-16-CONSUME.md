
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic teamAcustomers \
    --from-beginning \
    --timeout-ms 10000 \
    --property print.headers=true 
gateway_encrypted:   	158083938	{"name":"tom","username":"tom@conduktor.io","password":"AAAABQG4GC0DER/V6ayb0lD6yvJHcy7LxWTV2OKRmz7LAjDaEeJccwYzfcrwldGp3u/9scA=","visa":"AAAABQG58l2Fkec5o6dH4QdcmnrDLU2HLkXsdHrSaTWIBRJ03L80URxzJZN1HlAQI889","address":"Chancery lane, London"}
gateway_encrypted:   	158083938	{"name":"florent","username":"florent@conduktor.io","password":"AAAABQG4GC0Do+gvVRgulCjfX5Adltb5+tI9TAjqtfOJfpZZUQ7Y9K6qIyeGK1hSNPkLWA==","visa":"AAAABQG58l2FjXqVKtdnzlDzxsStpoeedL0eNJOYMVz3f9zAZ+BRKbzUZ+LeQGCHyxVEpb3f","address":"Dubai, UAE"}
[2024-01-22 18:58:34,124] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages

```

</details>
      
