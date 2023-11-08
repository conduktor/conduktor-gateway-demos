cat invalid-payload.json | jq -c | \
    kafka-avro-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-avro \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=2