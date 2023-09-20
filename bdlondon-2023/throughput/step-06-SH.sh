kafka-producer-perf-test \
    --topic physical-kafka \
    --throughput -1 \
    --num-records 2500000 \
    --record-size 255 \
    --producer-props bootstrap.servers=localhost:29092,localhost:29093,localhost:29094