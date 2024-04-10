#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config passthrough-sa.properties \
    --topic red-cars \
    --from-beginning \
    --timeout-ms 10000 | jq
