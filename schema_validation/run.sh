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
    --topic sr-topic
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic sr-topic
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
    --user admin:conduktor \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/sr-id-required\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.safeguard.TopicRequiredSchemaIdPolicyPlugin\",
        \"priority\": 100,
        \"config\": {
            \"topic\": \"sr-topic\",
            \"schemaIdRequired\": true
        }
    }'
"""
docker compose exec kafka-client \
  curl \
    --user admin:conduktor \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/sr-id-required" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.safeguard.TopicRequiredSchemaIdPolicyPlugin",
        "priority": 100,
        "config": {
            "topic": "sr-topic",
            "schemaIdRequired": true
        }
    }'
type """docker compose exec kafka-client \\
    curl \\
        --silent \\
        --user admin:conduktor \\
        --request GET \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/sr-id-required\" \\
        --header 'Content-Type: application/json' | jq
"""
docker compose exec kafka-client \
    curl \
        --silent \
        --user admin:conduktor \
        --request GET "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/sr-id-required" \
        --header 'Content-Type: application/json' | jq
type """echo '{\"msg\": \"hello world\"}' | 
  docker compose exec -T kafka-client \\
      kafka-console-producer \\
          --bootstrap-server conduktor-gateway:6969 \\
          --producer.config /clientConfig/gateway.properties \\
          --topic sr-topic
"""
echo '{"msg": "hello world"}' | 
  docker compose exec -T kafka-client \
      kafka-console-producer \
          --bootstrap-server conduktor-gateway:6969 \
          --producer.config /clientConfig/gateway.properties \
          --topic sr-topic
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
        --topic sr-topic \\
        --property schema.registry.url=http://schema-registry-dev:8081 \\
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
        --topic sr-topic \
        --property schema.registry.url=http://schema-registry-dev:8081 \
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
type """docker compose exec kafka-client \\
  curl \\
    --user admin:conduktor \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/valid-schema-is-required\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin\",
        \"priority\": 100,
        \"config\": {
            \"topic\": \"sr-topic\",
            \"schemaIdRequired\": true,
            \"validateSchema\": true,
            \"schemaRegistryConfig\": {
                \"host\": \"http://schema-registry:8081\"
            }
        }
    }'
"""
docker compose exec kafka-client \
  curl \
    --user admin:conduktor \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/valid-schema-is-required" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin",
        "priority": 100,
        "config": {
            "topic": "sr-topic",
            "schemaIdRequired": true,
            "validateSchema": true,
            "schemaRegistryConfig": {
                "host": "http://schema-registry:8081"
            }
        }
    }'
type """docker compose exec kafka-client \\
    curl \\
        --silent \\
        --user admin:conduktor \\
        --request GET \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/valid-schema-is-required\" \\
        --header 'Content-Type: application/json' | jq
"""
docker compose exec kafka-client \
    curl \
        --silent \
        --user admin:conduktor \
        --request GET "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/valid-schema-is-required" \
        --header 'Content-Type: application/json' | jq
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
        --topic sr-topic \\
        --property schema.registry.url=http://schema-registry-dev:8081 \\
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
        --topic sr-topic \
        --property schema.registry.url=http://schema-registry-dev:8081 \
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
type """docker compose exec kafka-client \\
  curl --silent http://schema-registry:8081/subjects/ | jq
"""
docker compose exec kafka-client \
  curl --silent http://schema-registry:8081/subjects/ | jq
type """docker compose exec kafka-client \\
  curl --silent http://schema-registry-dev:8081/subjects/ | jq
"""
docker compose exec kafka-client \
  curl --silent http://schema-registry-dev:8081/subjects/ | jq
type """docker compose exec kafka-client \\
  curl --silent http://schema-registry-dev:8081/subjects/sr-topic-value/versions/1 | jq
"""
docker compose exec kafka-client \
  curl --silent http://schema-registry-dev:8081/subjects/sr-topic-value/versions/1 | jq
