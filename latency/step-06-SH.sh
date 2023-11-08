kafka-run-class kafka.tools.EndToEndLatency \
    localhost:19092,localhost:19093,localhost:19094 \
    physical-kafka 10000 all 255