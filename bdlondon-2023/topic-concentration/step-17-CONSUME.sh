kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic concentrated-topic-with-100-partitions \
    --from-beginning \
    --timeout-ms 5000 \
    --property print.headers=true
