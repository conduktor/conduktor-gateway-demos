#!/bin/bash
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server broker-sni-gateway1main3.gateway-sni.conduktor.local:6969 \
    --topic clientTopic \
    --from-beginning \
    --max-messages 2 \
    --consumer.config /clientConfig/client.config