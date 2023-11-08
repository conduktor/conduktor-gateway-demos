schema='{
    "title": "Customer",
    "type": "object",
    "properties": {
      "name": { "type": "string" },
      "username": { "type": "string" },
      "password": { "type": "string" },
      "visa": { "type": "string" },
      "address": {
        "type": "object",
        "properties": {
          "location": { "type": "string" },
          "town": { "type": "string" },
          "country": { "type": "string" }
        }
      }
    }
}'

echo '{ 
    "name": "tom",
    "username": "tom@conduktor.io",
    "password": "motorhead",
    "visa": "#abc123",
    "address": {
      "location": "12 Chancery lane",
      "town": "London",
      "country": "UK"
    }
}' | \
  jq -c | \
    kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers \
        --property schema.registry.url=http://localhost:8081 \
        --property "value.schema=$schema" 2>&1 /dev/null

echo '{
    "name": "florent",
    "username": "florent@conduktor.io",
    "password": "kitesurf",
    "visa": "#888999XZ;",
    "address": {
      "location": "4th Street, Jumeirah",
      "town": "Dubai",
      "country": "UAE"
    }
}' | \
  jq -c | \
    kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers \
        --property schema.registry.url=http://localhost:8081 \
        --property "value.schema=$schema" 2>&1 /dev/null