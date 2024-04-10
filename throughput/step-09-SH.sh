#!/bin/bash
kafka-producer-perf-test \
    --topic via-gateway \
    --throughput -1 \
    --num-records 2500000 \
    --record-size 255 \
    --producer-props bootstrap.servers=localhost:6969 \
    --producer.config teamA-sa.properties