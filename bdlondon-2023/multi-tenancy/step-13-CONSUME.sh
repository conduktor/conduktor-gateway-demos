kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic londonTopic \
    --from-beginning \
    --timeout-ms 5000 | jq
