kafka-console-consumer \
    --bootstrap-server localhost:39092,localhost:39093,localhost:39094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 3 | jq
