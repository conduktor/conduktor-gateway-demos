#!/bin/bash
echo "Hello world 1" | docker compose exec -i kafka-client \
  kafka-console-producer \
    --bootstrap-server broker-sni-gateway1main1.gateway-sni.conduktor.local:6969 \
    --topic clientTopic \
    --producer.config /clientConfig/client.config