#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --topic red-cars \
    --from-beginning \
    --timeout-ms 10000 | jq
