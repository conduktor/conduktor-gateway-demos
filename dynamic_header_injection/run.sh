#!/bin/sh
function execute() {
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
    eval "$*"
}

execute """docker compose up --wait --detach
"""

execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic injectHeaderTopic
"""

execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic removeHeaderKeyPatternTopic
"""

execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic removeHeaderValuePatternTopic
"""

execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic removeHeaderKeyValuePatternTopic
"""

execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --list
"""

execute """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user admin:conduktor \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/username/someUsername/interceptor/injectHeader\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.DynamicHeaderInjectionPlugin\",
        \"priority\": 100,
        \"config\": {
            \"topic\": \"injectHeaderTopic\",
            \"headers\": {
              \"X-RAW_KEY\": \"a value\",
              \"X-USER_IP\": \"{{userIp}}\",
              \"X-USERNAME\": \"{{user}}\",
              \"X-USER_IP_GATEWAY_IP_USERNAME\": \"{{userIp}} to {{gatewayIp}} of {{user}}\"
            }
        }
    }'
"""

execute """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request GET \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/username/someUsername/interceptors\" \\
    --header 'Content-Type: application/json' | jq
"""

execute """echo '{\"message\": \"hello world\"}' | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/gateway.properties \\
      --topic injectHeaderTopic
"""

execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/gateway.properties \\
    --topic injectHeaderTopic \\
    --from-beginning \\
    --max-messages 1 \\
    --property print.headers=true
"""

execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server kafka1:9092 \\
    --topic someClusterinjectHeaderTopic \\
    --from-beginning \\
    --max-messages 1 \\
    --property print.headers=true
"""

execute """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/username/someUsername/interceptor/removeHeader\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.safeguard.MessageHeaderRemovalPlugin\",
        \"priority\": 100,
        \"config\": {
            \"topic\": \"removeHeaderKeyPatternTopic\",
            \"headerKeyRegex\": \"k0.*\"
          }
    }'
"""

execute """echo 'k0:v0,k1:v1^key_pattern' | docker compose exec -T kafka-client \\
    kafka-console-producer \\
        --bootstrap-server conduktor-gateway:6969 \\
        --producer.config /clientConfig/gateway.properties \\
        --topic removeHeaderKeyPatternTopic \\
        --property parse.key=false \\
        --property parse.headers=true \\
        --property headers.delimiter=^ \\
        --property headers.separator=, \\
        --property headers.key.separator=:
"""

execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/gateway.properties \\
    --topic removeHeaderKeyPatternTopic \\
    --from-beginning \\
    --max-messages 1 \\
    --property print.headers=true
"""

execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server kafka1:9092 \\
    --topic someClusterremoveHeaderKeyPatternTopic \\
    --from-beginning \\
    --max-messages 1 \\
    --property print.headers=true
"""

