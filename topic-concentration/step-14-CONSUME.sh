#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic concentrated-topic-with-10-partitions \
    --from-beginning \
    --timeout-ms 10000 | jq
