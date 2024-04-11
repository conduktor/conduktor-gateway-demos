#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic us_cars \
    --from-beginning \
    --timeout-ms 10000 | jq
