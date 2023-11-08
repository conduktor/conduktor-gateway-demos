kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config passthrough-sa.properties \
    --topic cars \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
 | jq
