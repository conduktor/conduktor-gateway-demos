#!/bin/bash
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 100 \
    --create --if-not-exists \
    --topic concentrated
