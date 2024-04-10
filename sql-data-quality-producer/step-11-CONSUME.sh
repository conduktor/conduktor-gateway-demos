#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 10000 \
    --property print.key=true \
    --property print.headers=true | jq
