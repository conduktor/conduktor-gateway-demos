#!/bin/bash
schema='{
            "type": "record",
            "name": "car",
            "fields": [
              {"name": "type", "type": "string"},
              {"name": "price", "type": "long"},
              {"name": "color", "type": "string"}
            ]
          }'
echo '{"type":"Sports","price":75,"color":"blue"}' | \
    kafka-avro-console-producer  \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars \
        --property schema.registry.url=http://localhost:8081 \
        --property "value.schema=$schema"

echo '{"type":"SUV","price":55,"color":"red"}' | \
    kafka-avro-console-producer  \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars \
        --property schema.registry.url=http://localhost:8081 \
        --property "value.schema=$schema"