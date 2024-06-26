#!/bin/bash
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 2 \
    --partitions 3 \
    --create --if-not-exists \
    --topic roads
