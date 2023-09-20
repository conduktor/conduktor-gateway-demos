kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 5000 | jq
