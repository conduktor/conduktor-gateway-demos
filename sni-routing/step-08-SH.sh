#!/bin/bash
echo "Hello world 2" | docker compose exec -i kafka-client \
  kafka-console-producer \
    --bootstrap-server broker-sni-gateway2main2.gateway-sni.conduktor.local:6969 \
    --topic clientTopic \
    --producer.config /clientConfig/client.config