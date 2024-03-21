#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-full-payload-level-encryption \
    --from-beginning \
    --timeout-ms 10000 | jq
