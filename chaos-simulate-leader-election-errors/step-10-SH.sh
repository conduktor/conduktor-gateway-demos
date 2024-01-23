kafka-producer-perf-test \
  --producer-props bootstrap.servers=localhost:6969 \
  --producer.config teamA-sa.properties \
  --record-size 10 \
  --throughput 1 \
  --num-records 10 \
  --topic my-topic