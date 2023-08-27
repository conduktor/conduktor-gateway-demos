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
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/someCluster/username/someUsername \\
    --header \"content-type:application/json\" \\
    --data-raw '{\"lifeTimeSeconds\":7776000}' | jq 
"""
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/someCluster/username/someUsername \
    --header "content-type:application/json" \
    --data-raw '{"lifeTimeSeconds":7776000}' | jq 
type """{
  \"token\" : \"eyJhbGciOiJIUzI1NiJ9.eyJvcmdJZCI6MSwiY2x1c3RlcklkIjoiY2x1c3RlcjEiLCJ1c2VybmFtZSI6InRlc3RAY29uZHVrdG9yLmlvIn0.XhB1e_ZXvgZ8zIfr28UQ33S8VA7yfWyfdM561Em9lrM\"
}
"""
{
  "token" : "eyJhbGciOiJIUzI1NiJ9.eyJvcmdJZCI6MSwiY2x1c3RlcklkIjoiY2x1c3RlcjEiLCJ1c2VybmFtZSI6InRlc3RAY29uZHVrdG9yLmlvIn0.XhB1e_ZXvgZ8zIfr28UQ33S8VA7yfWyfdM561Em9lrM"
}
type """cat clientConfig/gateway.properties
"""
cat clientConfig/gateway.properties
type """cat clientConfig/gateway.properties
"""
cat clientConfig/gateway.properties
type """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create \\
    --topic my-topic
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create \
    --topic my-topic
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
type """echo '{\"message\": \"hello world\"}' | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/gateway.properties \\
      --topic my-topic
"""
echo '{"message": "hello world"}' | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
      --bootstrap-server conduktor-gateway:6969 \
      --producer.config /clientConfig/gateway.properties \
      --topic my-topic
type """docker compose exec kafka-client \\
  kafka-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --consumer.config /clientConfig/gateway.properties \\
    --topic my-topic \\
    --from-beginning \\
    --max-messages 1 | jq
"""
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/gateway.properties \
    --topic my-topic \
    --from-beginning \
    --max-messages 1 | jq
