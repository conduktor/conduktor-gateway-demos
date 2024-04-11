#!/bin/bash
kafka-avro-console-consumer  \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --property schema.registry.url=http://localhost:8081 \
    --from-beginning \
    --max-messages 2 2>&1 | grep "{" | jq