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
    --command-config /clientConfig/london.properties \\
    --create --topic londonTopic
"""
execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/paris.properties \\
    --create --topic parisTopic
"""
execute """docker compose exec kafka-client \\
    kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/london.properties \\
    --list
"""
execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/paris.properties \\
    --list
"""
execute """echo testMessageLondon | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/london.properties \\
      --topic londonTopic
"""
execute """echo testMessageParis | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/paris.properties \\
      --topic parisTopic
"""
execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/london.properties \\
    --topic londonTopic \\
    --from-beginning \\
    --max-messages 1
"""
execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/paris.properties \\
    --topic parisTopic \\
    --from-beginning \\
    --max-messages 1
"""
execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server kafka1:9092 \\
    --create --if-not-exists \ 
    --topic existingLondonTopic \\
"""
execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server kafka1:9092 \\
    --create --topic existingSharedTopic
"""
execute """echo existingLondonMessage | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
    --bootstrap-server kafka1:9092 \\
    --topic existingLondonTopic \\
"""
execute """echo existingSharedMessage | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
    --bootstrap-server kafka1:9092 \\
    --topic existingSharedTopic
"""
execute """docker compose exec kafka-client \\
 curl \\
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/london/topics/existingLondonTopic \\
    --user admin:conduktor \\
    --header 'Content-Type: application/json' \\
    --data-raw '{ 
        \"physicalTopicName\": \"existingLondonTopic\",
        \"readOnly\": false,
        \"concentrated\": false
        }'
"""
execute """docker compose exec kafka-client \\
 curl \\
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/london/topics/existingSharedTopic \\
    --user admin:conduktor \\
    --header 'Content-Type: application/json' \\
    --data-raw '{ 
        \"physicalTopicName\": \"existingSharedTopic\",
        \"readOnly\": false,
        \"concentrated\": false
        }'
"""
execute """docker compose exec kafka-client \\
 curl \\
    --user admin:conduktor \\
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/paris/topics/existingSharedTopic \\
    --header 'Content-Type: application/json' \\
    --data-raw '{ 
        \"physicalTopicName\": \"existingSharedTopic\",
        \"readOnly\": false,
        \"concentrated\": false
        }'
"""
execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/london.properties \\
    --list
"""
execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/paris.properties \\
    --list
"""
execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/london.properties \\
    --topic existingLondonTopic \\
    --from-beginning \\
    --max-messages 1
"""
execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/london.properties \\
    --topic existingSharedTopic \\
    --from-beginning \\
    --max-messages 1
"""
execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/paris.properties \\
    --topic existingSharedTopic \\
    --from-beginning \\
    --max-messages 1
"""
