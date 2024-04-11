#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --timeout-ms 10000 | jq
