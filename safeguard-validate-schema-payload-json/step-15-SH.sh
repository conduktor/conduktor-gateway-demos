#!/bin/bash
MAGIC_BYTE="\000"
SCHEMA_ID="\000\000\000\001"
JSON_PAYLOAD=$(cat invalid-payload.json | jq -c)
printf "${MAGIC_BYTE}${SCHEMA_ID}${JSON_PAYLOAD}" | \
  kcat \
    -b localhost:6969 \
    -X security.protocol=SASL_PLAINTEXT \
    -X sasl.mechanism=PLAIN \
    -X sasl.username=sa \
    -X sasl.password=$(cat teamA-sa.properties | awk -F"'" '/password=/{print $4}') \
    -P \
    -t topic-json-schema