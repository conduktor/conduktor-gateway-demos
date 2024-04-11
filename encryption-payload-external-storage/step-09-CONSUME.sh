#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _conduktor_gateway_encryption_configs \
    --from-beginning \
    --timeout-ms 10000 | jq
