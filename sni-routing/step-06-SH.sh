#!/bin/bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server broker-sni-gateway1main1.gateway-sni.conduktor.local:6969 \
    --create \
    --replication-factor 3 \
    --partitions 1 \
    --topic clientTopic \
    --command-config /clientConfig/client.config