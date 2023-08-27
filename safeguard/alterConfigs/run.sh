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
    --topic safeguardTopic
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic safeguardTopic
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
type """docker-compose exec kafka-client \\
  curl \\
    --user \"admin:conduktor\" \\
    --request POST conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/username/someUsername/interceptor/guard-alter-configs \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin\",
        \"priority\": 100,
        \"config\": {
          \"topic\": \".*\",
          \"retentionMs\": {
            \"min\": 86400000,
            \"max\": 432000000
          }
        }  
    }'
"""
docker-compose exec kafka-client \
  curl \
    --user "admin:conduktor" \
    --request POST conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/username/someUsername/interceptor/guard-alter-configs \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin",
        "priority": 100,
        "config": {
          "topic": ".*",
          "retentionMs": {
            "min": 86400000,
            "max": 432000000
          }
        }  
    }'
type """docker compose exec kafka-client \\
  kafka-configs \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --alter --topic safeguardTopic \\
    --add-config retention.ms=10000
"""
docker compose exec kafka-client \
  kafka-configs \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --alter --topic safeguardTopic \
    --add-config retention.ms=10000
type """docker compose exec kafka-client \\
  kafka-configs \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --alter \\
    --topic safeguardTopic \\
    --add-config retention.ms=86400001
"""
docker compose exec kafka-client \
  kafka-configs \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --alter \
    --topic safeguardTopic \
    --add-config retention.ms=86400001
type """docker compose exec kafka-client \\
  kafka-configs \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --describe \\
    --topic safeguardTopic
"""
docker compose exec kafka-client \
  kafka-configs \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --describe \
    --topic safeguardTopic
type """Dynamic configs for topic safeguardTopic are:
  retention.ms=86400001 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.ms=86400001}
"""
Dynamic configs for topic safeguardTopic are:
  retention.ms=86400001 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.ms=86400001}
type """docker compose --profile platform up --wait --detach
"""
docker compose --profile platform up --wait --detach
