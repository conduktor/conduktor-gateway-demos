#!/bin/bash
echo '{"type":"Ferrari","color":"red","price":10000}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars

echo '{"type":"RollsRoyce","color":"black","price":9000}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars

echo '{"type":"Mercedes","color":"black","price":6000}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars