kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-third-party.properties \
    --topic customers \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
