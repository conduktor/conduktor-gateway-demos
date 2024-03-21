#!/bin/bash
valueSchema=$(echo '{
    "title": "Customer",
    "type": "object",
    "properties": {
      "name": { "type": "string" },
      "username": { "type": "string" },
      "password": { "type": "string", "conduktor.keySecretId": "password-secret", "conduktor.algorithm.type": "AES_GCM", "conduktor.algorithm.kms": "IN_MEMORY" },
      "visa": { "type": "string", "conduktor.keySecretId": "conduktor.visa-secret", "algorithm.type": "AES_GCM", "conduktor.algorithm.kms": "IN_MEMORY" },
      "address": {
        "type": "object",
        "properties": {
          "location": { "type": "string", "conduktor.tags": ["MY_TAG", "PII", "GDPR", "MY_OTHER_TAG"] },
          "town": { "type": "string" },
          "country": { "type": "string" }
        }
      }
    }
}' | jq -c)

keySchema=$(echo '{
    "title": "Metadata",
    "type": "object",
    "properties": {
        "sessionId": {"type": "string"},
        "authenticationToken": {"type": "string", "conduktor.keySecretId": "token-secret"},
        "deviceInformation": {"type": "string", "conduktor.algorithm": "AES128_CTR_HMAC_SHA256" }
    }
}' | jq -c)

invalidKeyTom=$(echo '{
        "sessionId": "session-id-tom",
        "authenticationToken": "authentication-token-tom",
        "deviceInformation": "device-information-tom"
    }' | jq -c)

invalidValueTom=$(echo '{
        "name": "tom",
        "username": "tom@conduktor.io",
        "password": "motorhead",
        "visa": "#abc123",
        "address": {
          "location": "12 Chancery lane",
          "town": "London",
          "country": "UK"
        }
    }' | jq -c)

invalidInputTom="$invalidKeyTom|$invalidValueTom"
echo $invalidInputTom | \
kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers \
        --property schema.registry.url=http://localhost:8081 \
        --property parse.key=true \
        --property key.separator="|" \
        --property value.schema=$valueSchema \
        --property key.schema=$keySchema 2>&1 /dev/null

invalidKeyLaura=$(echo '{
        "sessionId": "session-id-laura",
        "authenticationToken": "authentication-token-laura",
        "deviceInformation": "device-information-laura"
    }' | jq -c)

invalidValueLaura=$(echo '{
        "name": "laura",
        "username": "laura@conduktor.io",
        "password": "kitesurf",
        "visa": "#888999XZ;",
        "address": {
          "location": "4th Street, Jumeirah",
          "town": "Dubai",
          "country": "UAE"
        }
    }' | jq -c)

invalidInputLaura="$invalidKeyLaura|$invalidValueLaura"
echo $invalidInputLaura | \
kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers \
        --property schema.registry.url=http://localhost:8081 \
        --property parse.key=true \
        --property key.separator="|" \
        --property value.schema=$valueSchema \
        --property key.schema=$keySchema 2>&1 /dev/null