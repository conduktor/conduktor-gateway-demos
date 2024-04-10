#!/bin/bash
echo '{
    "name": "conduktor",
    "username": "test@conduktor.io",
    "password": "password1",
    "visa": "visa123456",
    "address": "Conduktor Towers, London"
}' | \
  jq -c | \
      kafka-json-schema-console-producer  \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema='{
            "title": "User",
            "type": "object",
            "properties": {
                "name": { "type": "string" },
                "username": { "type": "string" },
                "password": { "type": "string" },
                "visa": { "type": "string" },
                "address": { "type": "string" }
            }
        }'