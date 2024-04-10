#!/bin/bash
kafka-producer-perf-test \
  --producer.config teamA-sa.properties \
  --record-size 10 \
  --throughput 1 \
  --num-records 10 \
  --producer-prop retries=5 \
  --topic my-topic