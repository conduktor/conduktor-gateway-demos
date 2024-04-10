#!/bin/bash
echo '{"name":"Hi","age":7,"email":"john.doe@example.com","address":{"street":"123 Main St","city":"Anytown"},"hobbies":["reading","cycling"],"friends":[{"name":"Friend1","age":17},{"name":"Friend2","age":18}]}' | \
    kafka-avro-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-avro \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=2