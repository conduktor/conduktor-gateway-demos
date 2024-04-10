#!/bin/bash
echo 'X-HEADER-1:value1,X-HEADER-2:value2\t{"year":2023,"make":"Vinfast"}\t{"type":"Trucks","price":2500,"color":"red"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --property "parse.key=true" \
        --property "parse.headers=true" \
        --topic cars