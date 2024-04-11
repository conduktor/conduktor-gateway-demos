#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 15000 | jq
