#!/bin/bash
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
