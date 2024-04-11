#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 | jq
