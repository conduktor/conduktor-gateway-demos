#!/bin/bash
kafka-run-class kafka.tools.EndToEndLatency \
    localhost:6969 \
    via-gateway 10000 all 255 \
    teamA-sa.properties