kafka-avro-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-avro \
    --from-beginning \
    --timeout-ms 3000