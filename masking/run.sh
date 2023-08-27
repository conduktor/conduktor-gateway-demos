#!/bin/sh
function type() {
    chars=$(echo "$*" | wc -c)
    printf "$"
    sleep 2
    if [ "$chars" -lt 100 ] ; then
        echo "$*" | pv -qL 50
    elif [ "$chars" -lt 250 ] ; then
        echo "$*" | pv -qL 100
    elif [ "$chars" -lt 500 ] ; then
        echo "$*" | pv -qL 200
    else
        echo "$*" | pv -qL 400
    fi
}
type """docker compose up --wait --detach
"""
docker compose up --wait --detach
type """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic maskedTopic
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic maskedTopic
type """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --list
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --list
type """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/masker\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
          \"pluginClass\": \"io.conduktor.gateway.interceptor.FieldLevelDataMaskingPlugin\",
          \"priority\": 100,
          \"config\": {
            \"schemaRegistryConfig\": {
                \"host\": \"http://schema-registry:8081\"
            },
            \"policies\": [
              {
                \"name\": \"Mask password\",
                \"rule\": {
                  \"type\": \"MASK_ALL\"
                },
                \"fields\": [
                  \"password\"
                ]
              },
              {
                \"name\": \"Mask visa\",
                \"rule\": {
                  \"type\": \"MASK_LAST_N\",
                  \"maskingChar\": \"X\",
                  \"numberOfChars\": 4
                },
                \"fields\": [
                  \"visa\"
                ]
              }
            ]
          }
        }'
"""
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/masker" \
    --header 'Content-Type: application/json' \
    --data-raw '{
          "pluginClass": "io.conduktor.gateway.interceptor.FieldLevelDataMaskingPlugin",
          "priority": 100,
          "config": {
            "schemaRegistryConfig": {
                "host": "http://schema-registry:8081"
            },
            "policies": [
              {
                "name": "Mask password",
                "rule": {
                  "type": "MASK_ALL"
                },
                "fields": [
                  "password"
                ]
              },
              {
                "name": "Mask visa",
                "rule": {
                  "type": "MASK_LAST_N",
                  "maskingChar": "X",
                  "numberOfChars": 4
                },
                "fields": [
                  "visa"
                ]
              }
            ]
          }
        }'
type """echo '{ 
    \"name\": \"conduktor\",
    \"username\": \"test@conduktor.io\",
    \"password\": \"password1\",
    \"visa\": \"visa123456\",
    \"address\": \"Conduktor Towers, London\" 
}' | jq -c | docker compose exec -T schema-registry \\
    kafka-json-schema-console-producer  \\
        --bootstrap-server conduktor-gateway:6969 \\
        --producer.config /clientConfig/gateway.properties \\
        --topic maskedTopic \\
        --property schema.registry.url=http://schema-registry:8081 \\
        --property value.schema='{ 
            \"title\": \"User\",
            \"type\": \"object\",
            \"properties\": { 
                \"name\": { \"type\": \"string\" },
                \"username\": { \"type\": \"string\" },
                \"password\": { \"type\": \"string\" },
                \"visa\": { \"type\": \"string\" },
                \"address\": { \"type\": \"string\" } 
            } 
        }'
"""
echo '{ 
    "name": "conduktor",
    "username": "test@conduktor.io",
    "password": "password1",
    "visa": "visa123456",
    "address": "Conduktor Towers, London" 
}' | jq -c | docker compose exec -T schema-registry \
    kafka-json-schema-console-producer  \
        --bootstrap-server conduktor-gateway:6969 \
        --producer.config /clientConfig/gateway.properties \
        --topic maskedTopic \
        --property schema.registry.url=http://schema-registry:8081 \
        --property value.schema='{ 
            "title": "User",
            "type": "object",
            "properties": { 
                "name": { "type": "string" },
                "username": { "type": "string" },
                "password": { "type": "string" },
                "visa": { "type": "string" },
                "address": { "type": "string" } 
            } 
        }'
type """docker compose exec schema-registry \\
   kafka-json-schema-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/gateway.properties \\
    --property schema.registry.url=http://schema-registry:8081 \\
    --topic maskedTopic \\
    --from-beginning \\
    --max-messages 1 | jq
"""
docker compose exec schema-registry \
   kafka-json-schema-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/gateway.properties \
    --property schema.registry.url=http://schema-registry:8081 \
    --topic maskedTopic \
    --from-beginning \
    --max-messages 1 | jq
type """docker compose exec schema-registry \\
  kafka-json-schema-console-consumer \\
    --bootstrap-server kafka1:9092 \\
    --property schema.registry.url=http://schema-registry:8081 \\
    --topic someClustermaskedTopic \\
    --from-beginning \\
    --max-messages 1 | jq
"""
docker compose exec schema-registry \
  kafka-json-schema-console-consumer \
    --bootstrap-server kafka1:9092 \
    --property schema.registry.url=http://schema-registry:8081 \
    --topic someClustermaskedTopic \
    --from-beginning \
    --max-messages 1 | jq
