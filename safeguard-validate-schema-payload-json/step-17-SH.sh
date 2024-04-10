#!/bin/bash
cat valid-payload.json | jq -c | \
    kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-json-schema \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=1