#!/bin/bash
echo 'my-header:{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}\t{"msg": "test key"}\t{"msg": "test value"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --property "parse.key=true" \
        --property "parse.headers=true" \
        --topic customers-fields-level-encryption