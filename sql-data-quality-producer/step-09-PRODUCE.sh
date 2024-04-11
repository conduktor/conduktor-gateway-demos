#!/bin/bash
echo '{"year":2010,"make":"BMW"}\t{"type":"Sports","price":1000,"color":"red"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --property "parse.key=true" \
        --topic cars