requiredMemory=$(( 2 * $(cat large-message.bin | wc -c | awk '{print $1}')))

kafka-producer-perf-test \
  --producer.config teamA-sa.properties \
  --topic large-messages \
  --throughput -1 \
  --num-records 1 \
  --payload-file large-message.bin \
  --producer-props \
    bootstrap.servers=localhost:6969 \
    max.request.size=$requiredMemory \
    buffer.memory=$requiredMemory