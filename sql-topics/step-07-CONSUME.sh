#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --topic cars \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 | jq
