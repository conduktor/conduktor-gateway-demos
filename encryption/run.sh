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
    --topic encryptedTopic
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic encryptedTopic
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
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/encrypt\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.EncryptPlugin\",
        \"priority\": 100,
        \"config\": {
            \"topic\": \"encryptedTopic\",
            \"schemaRegistryConfig\": {
                \"host\": \"http://schema-registry:8081\"
            },
            \"fields\": [ {
                \"fieldName\": \"password\",
                \"keySecretId\": \"password-secret\",
                \"algorithm\": { 
                    \"type\": \"AES_GCM\",
                    \"kms\": \"IN_MEMORY\"
                }
            },
            {
                \"fieldName\": \"visa\",
                \"keySecretId\": \"visa-scret\",
                \"algorithm\": {
                    \"type\": \"AES_GCM\",
                    \"kms\": \"IN_MEMORY\"
                }
            }]
        }
    }' 
"""
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/encrypt" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
        "priority": 100,
        "config": {
            "topic": "encryptedTopic",
            "schemaRegistryConfig": {
                "host": "http://schema-registry:8081"
            },
            "fields": [ {
                "fieldName": "password",
                "keySecretId": "password-secret",
                "algorithm": { 
                    "type": "AES_GCM",
                    "kms": "IN_MEMORY"
                }
            },
            {
                "fieldName": "visa",
                "keySecretId": "visa-scret",
                "algorithm": {
                    "type": "AES_GCM",
                    "kms": "IN_MEMORY"
                }
            }]
        }
    }' 
type """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
type """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/decrypt\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.DecryptPlugin\",
        \"priority\": 100,
        \"config\": {
            \"topic\": \"encryptedTopic\",
            \"schemaRegistryConfig\": {
                \"host\": \"http://schema-registry:8081\"
            }
        }
    }'
"""
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/decrypt" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
        "priority": 100,
        "config": {
            "topic": "encryptedTopic",
            "schemaRegistryConfig": {
                "host": "http://schema-registry:8081"
            }
        }
    }'
type """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
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
        --topic encryptedTopic \\
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
        --topic encryptedTopic \
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
    --topic encryptedTopic \\
    --from-beginning \\
    --max-messages 1 | jq
"""
docker compose exec schema-registry \
  kafka-json-schema-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/gateway.properties \
    --topic encryptedTopic \
    --from-beginning \
    --max-messages 1 | jq
type """docker compose exec schema-registry \\
  kafka-json-schema-console-consumer \\
    --bootstrap-server kafka1:9092 \\
    --topic someClusterencryptedTopic \\
    --from-beginning \\
    --max-messages 1 | jq
"""
docker compose exec schema-registry \
  kafka-json-schema-console-consumer \
    --bootstrap-server kafka1:9092 \
    --topic someClusterencryptedTopic \
    --from-beginning \
    --max-messages 1 | jq
type """docker compose exec kafka-client \\
    kafka-topics \\
        --bootstrap-server conduktor-gateway:6969 \\
        --command-config /clientConfig/gateway.properties \\
        --create --if-not-exists \\
        --topic encryption-performance
"""
docker compose exec kafka-client \
    kafka-topics \
        --bootstrap-server conduktor-gateway:6969 \
        --command-config /clientConfig/gateway.properties \
        --create --if-not-exists \
        --topic encryption-performance
type """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/performanceEncrypt\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.EncryptPlugin\",
        \"priority\": 100,
        \"config\": {
            \"topic\": \"encryption-performance\",
            \"fields\": [ { 
                \"fieldName\": \"password\",
                \"keySecretId\": \"password-secret\",
                \"algorithm\": { 
                    \"type\": \"AES_GCM\",
                    \"kms\": \"IN_MEMORY\"
                }
            },
            { 
                \"fieldName\": \"visa\",
                \"keySecretId\": \"visa-secret\",
                \"algorithm\": { 
                    \"type\": \"AES_GCM\",
                    \"kms\": \"IN_MEMORY\"
                } 
            }]
        }
    }'
"""
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/performanceEncrypt" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
        "priority": 100,
        "config": {
            "topic": "encryption-performance",
            "fields": [ { 
                "fieldName": "password",
                "keySecretId": "password-secret",
                "algorithm": { 
                    "type": "AES_GCM",
                    "kms": "IN_MEMORY"
                }
            },
            { 
                "fieldName": "visa",
                "keySecretId": "visa-secret",
                "algorithm": { 
                    "type": "AES_GCM",
                    "kms": "IN_MEMORY"
                } 
            }]
        }
    }'
type """cat customers.json
"""
cat customers.json
type """docker compose cp customers.json kafka-client:/home/appuser
"""
docker compose cp customers.json kafka-client:/home/appuser
type """docker compose exec kafka-client \\
    kafka-producer-perf-test \\
        --topic encryption-performance \\
        --throughput -1 \\
        --num-records 1000000 \\
        --producer-props bootstrap.servers=conduktor-gateway:6969 linger.ms=100 \\
        --producer.config /clientConfig/gateway.properties \\
        --payload-file customers.json
"""
docker compose exec kafka-client \
    kafka-producer-perf-test \
        --topic encryption-performance \
        --throughput -1 \
        --num-records 1000000 \
        --producer-props bootstrap.servers=conduktor-gateway:6969 linger.ms=100 \
        --producer.config /clientConfig/gateway.properties \
        --payload-file customers.json
