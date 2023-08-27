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
    --topic safeguardTopic
"""

execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --list
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --user \"admin:conduktor\" \\
    --request POST conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/username/someUsername/interceptor/guard-alter-configs \\
    --header \"Content-Type: application/json\" \\
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

execute """docker compose exec kafka-client \\
  kafka-configs \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --alter \\
    --topic safeguardTopic \\
    --add-config retention.ms=10000
"""

execute """docker compose exec kafka-client \\
  kafka-configs \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --alter \\
    --topic safeguardTopic \\
    --add-config retention.ms=86400001
"""

execute """docker compose exec kafka-client \\
  kafka-configs \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --describe \\
    --topic safeguardTopic
"""

execute """docker compose --profile platform up --wait --detach
"""

