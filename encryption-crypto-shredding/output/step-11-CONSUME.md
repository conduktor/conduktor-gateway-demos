
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
[2024-01-22 18:44:29,467] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
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
  "password": "AAAABQAAAEl2YXVsdDp2MTo3S2F3cHFyTEhRZ3hkd2ZiMnpPOWFnUEJNU09nN2V6OElJUkZaTlJ0ZHVFSFM5cUtyV0R2cW9TNkxoYkRFdz09xpFbv+O0Utw54N+5ToRvqirQhy8MdSqFVPMODF50FC1HG0W4Ucdib6HxvlI=",
  "visa": "AAAABQAAAEl2YXVsdDp2MTpkSlE0eHlGNFo0d3hIV2VPamUzdGdaWU43YWVwRnFjRSsxcnArUDFpNVBUcDROVWxuSS9EYXQ4aVVFa25EZz094Z6Fc/w9YV0joAS4vImBt4hhTNU5gm9iCsUy5yMXMQ2rP/Jwz/69+9yD",
  "address": "Chancery lane, London"
}

```

</details>
      
