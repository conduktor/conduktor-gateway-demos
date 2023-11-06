#!/bin/sh

docker compose up --wait --detach

echo "Generate client.properties file"
docker compose exec kafka-client sh -c "password=\$(curl --location 'http://conduktor-gateway:8888/admin/vclusters/v1/vcluster/someCluster/username/someUsername' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic YWRtaW46Y29uZHVrdG9y' \
--data '{ \"lifeTimeSeconds\": 7776000 }' | grep -o '\"token\":\"[^\"]*' | awk -F ':\"' '{print \$2}'); \
echo \"security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"someUsername\" password=\"\$password\";\" > client.properties"


echo "Creating a topic called conduktor-msk-topic"
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969,conduktor-gateway-1:6969 \
    --command-config client.properties \
    --create --if-not-exists \
    --topic conduktor-msk-topic

echo "Producing a message to gateway"
echo 'message test' | docker compose exec -T kafka-client \
  kafka-console-producer \
  --bootstrap-server conduktor-gateway:6969,conduktor-gateway-1:6969 \
  --producer.config client.properties \
  --topic conduktor-msk-topic

echo "Consuming a message from gateway\n"
docker compose exec kafka-client \
  kafka-console-consumer \
  --bootstrap-server conduktor-gateway:6969,conduktor-gateway-1:6969 \
  --consumer.config client.properties \
  --topic conduktor-msk-topic \
  --from-beginning \
  --max-messages 1

echo "\n"
docker compose down --volumes