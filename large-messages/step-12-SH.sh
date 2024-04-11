#!/bin/bash
kafka-console-consumer  \
  --bootstrap-server localhost:6969 \
  --consumer.config teamA-sa.properties \
  --topic large-messages \
  --from-beginning \
  --max-messages 1 > from-kafka.bin