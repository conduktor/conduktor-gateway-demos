
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 15000 \
 | jq
Processed a total of 3 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ",
  "address": "Dubai, UAE"
}
{
  "name": "thibaut",
  "username": "thibaut@conduktor.io",
  "password": "youpi",
  "visa": "#812SSS",
  "address": "Les ifs"
}

```

</details>
      
