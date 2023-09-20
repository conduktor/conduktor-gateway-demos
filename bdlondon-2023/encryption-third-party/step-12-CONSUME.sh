kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers \
    --from-beginning \
    --timeout-ms 5000 | jq
