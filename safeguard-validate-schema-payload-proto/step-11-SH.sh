#!/bin/bash
kafka-protobuf-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-protobuf \
    --from-beginning \
    --timeout-ms 3000