#!/bin/sh
function execute() {
    chars=$(echo "$*" | wc -c)
    sleep 2
    printf "$"
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
    --topic cars \\
    --replication-factor 1 \\
    --partitions 1
"""

execute """echo '{
    \"type\": \"Sports\",
    \"price\": 75,
    \"color\": \"blue\"
}' | jq -c | docker compose exec -T kafka-client \\
    kafka-console-producer \\
        --bootstrap-server conduktor-gateway:6969 \\
        --producer.config /clientConfig/gateway.properties \\
        --topic cars
"""

execute """echo '{
    \"type\": \"SUV\",
    \"price\": 55,
    \"color\": \"red\"
}' | jq -c | docker compose exec -T kafka-client \\
    kafka-console-producer \\
        --bootstrap-server conduktor-gateway:6969 \\
        --producer.config /clientConfig/gateway.properties \\
        --topic cars
"""

execute """docker compose exec kafka-client \\
    kafka-console-consumer \\
        --bootstrap-server conduktor-gateway:6969 \\
        --consumer.config /clientConfig/gateway.properties \\
        --topic cars \\
        --from-beginning \\
        --max-messages 2 | jq
"""

execute """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/red-cars-virtual-topic\" \\
    --header \"Content-Type: application/json\" \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.VirtualSqlTopicPlugin\",
        \"priority\": 100,
        \"config\": {
            \"virtualTopic\": \"red-cars\",
            \"statement\": \"SELECT type as redType, price FROM cars WHERE color = '\"'red'\"'\"
        }
    }'
"""

execute """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request GET \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/red-cars-virtual-topic\" | jq
"""

execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/gateway.properties \\
    --topic red-cars \\
    --from-beginning \\
    --max-messages 1 | jq
"""

execute """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/red-cars-virtual-topic\"
"""

