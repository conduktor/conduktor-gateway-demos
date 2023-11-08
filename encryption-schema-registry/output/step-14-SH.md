
<details>
<summary>Command output</summary>

```sh

kafka-json-schema-console-consumer \
  --bootstrap-server localhost:6969 \
  --consumer.config teamA-sa.properties \
  --property schema.registry.url=http://localhost:8081 \
  --topic customers \
  --from-beginning \
  --max-messages 2 2>&1 | grep '{' | jq
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": {
    "location": "12 Chancery lane",
    "town": "London",
    "country": "UK"
  }
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ;",
  "address": {
    "location": "4th Street, Jumeirah",
    "town": "Dubai",
    "country": "UAE"
  }
}

```

</details>
      
