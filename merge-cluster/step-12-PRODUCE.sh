#!/bin/bash
echo '{"name":"us_cars_record"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic us_cars