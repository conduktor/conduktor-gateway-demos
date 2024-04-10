#!/bin/bash
echo '{"name":"eu_cars_record"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic eu_cars