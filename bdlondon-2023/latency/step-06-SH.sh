kafka-run-class kafka.tools.EndToEndLatency \
    localhost:29092,localhost:29093,localhost:29094 \
    physical-kafka 10000 all 255