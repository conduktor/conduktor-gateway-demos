#!/bin/bash
kafka-json-schema-console-consumer \
--bootstrap-server localhost:6969 \
--topic with-schema \
--consumer.config teamA-sa.properties \
--from-beginning