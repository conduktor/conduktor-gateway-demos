#!/bin/bash
cat valid-payload.json | jq -c | \
    kafka-protobuf-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-protobuf \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=2