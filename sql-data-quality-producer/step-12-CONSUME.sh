#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:29093,localhost:29094 \
    --topic dead-letter-topic \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
    --property print.key=true \
    --property print.headers=true | jq
