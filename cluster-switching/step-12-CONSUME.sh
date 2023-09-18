kafka-console-consumer \
    --bootstrap-server localhost:39092,localhost:39093,localhost:39094 \
    --topic _topicMappings \
    --from-beginning \
    --max-messages 1 | jq
