kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic with-random-bytes \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
