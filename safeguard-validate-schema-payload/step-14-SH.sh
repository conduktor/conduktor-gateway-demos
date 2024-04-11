#!/bin/bash
echo '{"name":"Hi","age":7,"email":"john.doecom","address":{"street":"123 Main St","city":"a"},"hobbies":["reading","cycling"]}' | \
    kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-json \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=1