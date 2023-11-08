kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
