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
    --command-config /clientConfig/london.properties \\
    --create --topic londonTopic
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/london.properties \
    --create --topic londonTopic
type """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/paris.properties \\
    --create --topic parisTopic
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/paris.properties \
    --create --topic parisTopic
type """docker compose exec kafka-client \\
    kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/london.properties \\
    --list
"""
docker compose exec kafka-client \
    kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/london.properties \
    --list
type """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/paris.properties \\
    --list
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/paris.properties \
    --list
type """echo testMessageLondon | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/london.properties \\
      --topic londonTopic
"""
echo testMessageLondon | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
      --bootstrap-server conduktor-gateway:6969 \
      --producer.config /clientConfig/london.properties \
      --topic londonTopic
type """echo testMessageParis | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/paris.properties \\
      --topic parisTopic
"""
echo testMessageParis | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
      --bootstrap-server conduktor-gateway:6969 \
      --producer.config /clientConfig/paris.properties \
      --topic parisTopic
type """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/london.properties \\
    --topic londonTopic \\
    --from-beginning \\
    --max-messages 1
"""
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/london.properties \
    --topic londonTopic \
    --from-beginning \
    --max-messages 1
type """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/paris.properties \\
    --topic parisTopic \\
    --from-beginning \\
    --max-messages 1
"""
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/paris.properties \
    --topic parisTopic \
    --from-beginning \
    --max-messages 1
type """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server kafka1:9092 \\
    --create --if-not-exists \ 
    --topic existingLondonTopic \\
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --create --if-not-exists \ 
    --topic existingLondonTopic \
type """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server kafka1:9092 \\
    --create --topic existingSharedTopic
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --create --topic existingSharedTopic
type """echo existingLondonMessage | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
    --bootstrap-server kafka1:9092 \\
    --topic existingLondonTopic \\
"""
echo existingLondonMessage | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
    --bootstrap-server kafka1:9092 \
    --topic existingLondonTopic \
type """echo existingSharedMessage | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
    --bootstrap-server kafka1:9092 \\
    --topic existingSharedTopic
"""
echo existingSharedMessage | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
    --bootstrap-server kafka1:9092 \
    --topic existingSharedTopic
type """docker compose exec kafka-client \\
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
docker compose exec kafka-client \
 curl \
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/london/topics/existingLondonTopic \
    --user admin:conduktor \
    --header 'Content-Type: application/json' \
    --data-raw '{ 
        "physicalTopicName": "existingLondonTopic",
        "readOnly": false,
        "concentrated": false
        }'
type """docker compose exec kafka-client \\
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
docker compose exec kafka-client \
 curl \
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/london/topics/existingSharedTopic \
    --user admin:conduktor \
    --header 'Content-Type: application/json' \
    --data-raw '{ 
        "physicalTopicName": "existingSharedTopic",
        "readOnly": false,
        "concentrated": false
        }'
type """docker compose exec kafka-client \\
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
docker compose exec kafka-client \
 curl \
    --user admin:conduktor \
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/paris/topics/existingSharedTopic \
    --header 'Content-Type: application/json' \
    --data-raw '{ 
        "physicalTopicName": "existingSharedTopic",
        "readOnly": false,
        "concentrated": false
        }'
type """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/london.properties \\
    --list
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/london.properties \
    --list
type """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/paris.properties \\
    --list
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/paris.properties \
    --list
type """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/london.properties \\
    --topic existingLondonTopic \\
    --from-beginning \\
    --max-messages 1
"""
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/london.properties \
    --topic existingLondonTopic \
    --from-beginning \
    --max-messages 1
type """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/london.properties \\
    --topic existingSharedTopic \\
    --from-beginning \\
    --max-messages 1
"""
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/london.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --max-messages 1
type """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/paris.properties \\
    --topic existingSharedTopic \\
    --from-beginning \\
    --max-messages 1
"""
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/paris.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --max-messages 1
