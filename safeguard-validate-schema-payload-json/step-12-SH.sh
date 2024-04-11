#!/bin/bash
kafka-json-schema-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-json-schema \
    --from-beginning \
    --skip-message-on-error \
    --timeout-ms 3000