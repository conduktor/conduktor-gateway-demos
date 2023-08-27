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
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/username/someUsername/interceptor/guard-create-topics \\
    --header \"Content-Type: application/json\" \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin\",
        \"priority\": 100,
        \"config\": { 
            \"topic\": \"\",
            \"numPartition\": {
              \"min\": 3,
              \"max\":3,
              \"whatToDo\": \"BLOCK\"
            },
              \"replicationFactor\": {
                \"min\": 2,
                \"max\": 2,
                \"whatToDo\": \"OVERRIDE\",
                \"overrideValue\": 2
            }
        }
    }'
"""

execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create \\
    --topic invalidTopic \\
    --replication-factor 1 \\
    --partitions 10
"""

execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create \\
    --topic validTopic \\
    --replication-factor 2 \\
    --partitions 3
"""

