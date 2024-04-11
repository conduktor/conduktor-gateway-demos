#!/bin/bash
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 5 \
    --create --if-not-exists \
    --topic hold_many_concentrated_topics
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 5 \
    --config cleanup.policy=compact \
    --create --if-not-exists \
    --topic hold_many_concentrated_topics_compacted
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 5 \
    --config cleanup.policy=compact,delete \
    --create --if-not-exists \
    --topic hold_many_concentrated_topics_compacted_deleted
