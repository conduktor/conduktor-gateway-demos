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

execute """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server kafka1:9092 \\
    --create --if-not-exists \\
    --topic hold-many-virtual-topics \\
    --replication-factor 1 \\
    --partitions 10
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST 'conduktor-gateway:8888/admin/vclusters/v1/vcluster/someCluster/topics/concentrated-.%2A' \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"physicalTopicName\": \"hold-many-virtual-topics\",
        \"readOnly\": false,
        \"concentrated\": true
    }'
"""

execute """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create \\
    --topic concentrated-topic-with-10-partitions \\
    --replication-factor 1 \\
    --partitions 10
"""

execute """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create \\
    --topic concentrated-topic-with-100-partitions \\
    --replication-factor 1 \\
    --partitions 100
"""

execute """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server kafka1:9092 \\
    --list
"""

execute """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --list
"""

execute """echo '{\"type\": \"Sports\", \"price\": 75, \"color\": \"blue\"}' | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/gateway.properties \\
      --topic concentrated-topic-with-10-partitions
"""

execute """docker-compose exec kafka-client \\
  kafka-console-consumer  \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/gateway.properties \\
    --topic concentrated-topic-with-10-partitions \\
    --from-beginning \\
    --max-messages 1 | jq
"""

execute """echo '{\"msg\": \"hello world\"}' | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/gateway.properties \\
      --topic concentrated-topic-with-100-partitions
"""

execute """docker-compose exec kafka-client \\
  kafka-console-consumer  \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/gateway.properties \\
    --topic concentrated-topic-with-100-partitions \\
    --from-beginning \\
    --max-messages 1 | jq
"""

execute """docker-compose exec kafka-client \\
  kafka-console-consumer  \\
    --bootstrap-server kafka1:9092 \\
    --topic hold-many-virtual-topics \\
    --from-beginning \\
    --max-messages 2 | jq
"""

execute """docker-compose exec kafka-client \\
  kafka-console-consumer  \\
    --bootstrap-server kafka1:9092 \\
    --topic hold-many-virtual-topics \\
    --property print.headers=true \\
    --property print.partition=true \\
    --from-beginning \\
    --max-messages 2
"""

