kafka-console-consumer \
    --bootstrap-server localhost:6969,localhost:7969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --timeout-ms 5000 | jq
