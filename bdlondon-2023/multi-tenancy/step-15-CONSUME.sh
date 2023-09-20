kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config paris-sa.properties \
    --topic parisTopic \
    --from-beginning \
    --timeout-ms 5000 | jq
