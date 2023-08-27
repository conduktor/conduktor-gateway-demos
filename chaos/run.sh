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

type """cat clientConfig/gateway.properties
"""
cat clientConfig/gateway.properties
type """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic conduktorTopic
"""
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic conduktorTopic
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
    --user 'admin:conduktor' \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/broken-broker\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.chaos.SimulateBrokenBrokersPlugin\",
        \"priority\": 100,
        \"config\": {
            \"rateInPercent\": 30,
            \"errorMap\": {
                \"FETCH\": \"UNKNOWN_SERVER_ERROR\",
                \"PRODUCE\": \"CORRUPT_MESSAGE\"
            }
        }
    }'
"""
docker compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/broken-broker" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateBrokenBrokersPlugin",
        "priority": 100,
        "config": {
            "rateInPercent": 30,
            "errorMap": {
                "FETCH": "UNKNOWN_SERVER_ERROR",
                "PRODUCE": "CORRUPT_MESSAGE"
            }
        }
    }'
type """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request GET \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors\" \\
    --header 'Content-Type: application/json' | jq
"""
docker compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request GET "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors" \
    --header 'Content-Type: application/json' | jq
type """docker-compose exec kafka-client \\
  kafka-producer-perf-test \\
      --producer.config /clientConfig/gateway.properties \\
      --record-size 10 \\
      --throughput 10 \\
      --num-records 100 \\
      --topic conduktorTopic
"""
docker-compose exec kafka-client \
  kafka-producer-perf-test \
      --producer.config /clientConfig/gateway.properties \
      --record-size 10 \
      --throughput 10 \
      --num-records 100 \
      --topic conduktorTopic
type """[2023-07-12 12:12:11,213] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 64 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2023-07-12 12:12:12,109] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 74 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
...
10 records sent, 5.031447 records/sec (0.00 MB/sec), 14587.31 ms avg latency, 19299.00 ms max latency, 14557 ms 50th, 18895 ms 95th, 19299 ms 99th, 19299 ms 99.9th.
"""
[2023-07-12 12:12:11,213] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 64 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2023-07-12 12:12:12,109] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 74 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
...
10 records sent, 5.031447 records/sec (0.00 MB/sec), 14587.31 ms avg latency, 19299.00 ms max latency, 14557 ms 50th, 18895 ms 95th, 19299 ms 99th, 19299 ms 99.9th.
type """docker-compose exec kafka-client \\
  curl \\
    --user 'admin:conduktor' \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/broken-broker\"
"""
docker-compose exec kafka-client \
  curl \
    --user 'admin:conduktor' \
    --request DELETE "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/broken-broker"
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
type """docker-compose exec kafka-client \\
  kafka-producer-perf-test \\
      --producer.config /clientConfig/gateway.properties \\
      --record-size 100 \\
      --throughput 10 \\
      --num-records 100 \\
      --topic conduktorTopic
"""
docker-compose exec kafka-client \
  kafka-producer-perf-test \
      --producer.config /clientConfig/gateway.properties \
      --record-size 100 \
      --throughput 10 \
      --num-records 100 \
      --topic conduktorTopic
type """52 records sent, 10.3 records/sec (0.00 MB/sec), 16.0 ms avg latency, 388.0 ms max latency.
100 records sent, 10.001000 records/sec (0.00 MB/sec), 10.69 ms avg latency, 388.00 ms max latency, 5 ms 50th, 43 ms 95th, 388 ms 99th, 388 ms 99.9th.
"""
52 records sent, 10.3 records/sec (0.00 MB/sec), 16.0 ms avg latency, 388.0 ms max latency.
100 records sent, 10.001000 records/sec (0.00 MB/sec), 10.69 ms avg latency, 388.00 ms max latency, 5 ms 50th, 43 ms 95th, 388 ms 99th, 388 ms 99.9th.
type """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic conduktorTopicDuplicate
"""
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic conduktorTopicDuplicate
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/duplicate-resource\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.chaos.DuplicateResourcesPlugin\",
        \"priority\": 100,
        \"config\": {
            \"topic\": \"conduktorTopicDuplicate\",
            \"rateInPercent\": 100
        }
    }'
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/duplicate-resource" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.chaos.DuplicateResourcesPlugin",
        "priority": 100,
        "config": {
            "topic": "conduktorTopicDuplicate",
            "rateInPercent": 100
        }
    }'
type """echo '{\"message\": \"hello world\"}' | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/gateway.properties \\
      --topic conduktorTopicDuplicate
"""
echo '{"message": "hello world"}' | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
      --bootstrap-server conduktor-gateway:6969 \
      --producer.config /clientConfig/gateway.properties \
      --topic conduktorTopicDuplicate
type """docker-compose exec kafka-client \\
  kafka-console-consumer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --consumer.config /clientConfig/gateway.properties \\
      --from-beginning \\
      --topic conduktorTopicDuplicate \\
      --max-messages 2 | jq
"""
docker-compose exec kafka-client \
  kafka-console-consumer \
      --bootstrap-server conduktor-gateway:6969 \
      --consumer.config /clientConfig/gateway.properties \
      --from-beginning \
      --topic conduktorTopicDuplicate \
      --max-messages 2 | jq
type """docker-compose exec kafka-client \\
  curl \\
    --user 'admin:conduktor' \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/duplicate-resource\"
"""
docker-compose exec kafka-client \
  curl \
    --user 'admin:conduktor' \
    --request DELETE "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/duplicate-resource"
type """docker-compose exec kafka-client \  
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""
docker-compose exec kafka-client \  
  curl \
    --silent \
    --user "admin:conduktor" \
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/leader-election\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.chaos.SimulateLeaderElectionsErrorsPlugin\",
        \"priority\": 100,
        \"config\": {
          \"rateInPercent\": 50
        }
    }'
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/leader-election" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateLeaderElectionsErrorsPlugin",
        "priority": 100,
        "config": {
          "rateInPercent": 50
        }
    }'
type """docker-compose exec kafka-client \\
  kafka-producer-perf-test \\
      --producer.config /clientConfig/gateway.properties \\
      --record-size 100 \\
      --throughput 10 \\
      --num-records 10 \\
      --topic conduktorTopic
"""
docker-compose exec kafka-client \
  kafka-producer-perf-test \
      --producer.config /clientConfig/gateway.properties \
      --record-size 100 \
      --throughput 10 \
      --num-records 10 \
      --topic conduktorTopic
type """[2022-11-17 14:15:18,481] WARN [Producer clientId=perf-producer-client] Received invalid metadata error in produce request on partition conduktorTopic-0 due to org.apache.kafka.common.errors.NotLeaderOrFollowerException: For requests intended only for the leader, this error indicates that the broker is not the current leader. For requests intended for any replica, this error indicates that the broker is not a replica of the topic partition.. Going to request metadata update now (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 14:15:18,584] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 121 on topic-partition conduktorTopic-0, retrying (2147483588 attempts left). Error: NOT_LEADER_OR_FOLLOWER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 14:15:18,584] WARN [Producer clientId=perf-producer-client] Received invalid metadata error in produce request on partition conduktorTopic-0 due to org.apache.kafka.common.errors.NotLeaderOrFollowerException: For requests intended only for the leader, this error indicates that the broker is not the current leader. For requests intended for any replica, this error indicates that the broker is not a replica of the topic partition.. Going to request metadata update now (org.apache.kafka.clients.producer.internals.Sender)
1 records sent, 0.2 records/sec (0.00 MB/sec), 6511.0 ms avg latency, 6511.0 ms max latency.
10 records sent, 1.531159 records/sec (0.00 MB/sec), 6010.20 ms avg latency, 6511.00 ms max latency, 6118 ms 50th, 6511 ms 95th, 6511 ms 99th, 6511 ms 99.9th.
"""
[2022-11-17 14:15:18,481] WARN [Producer clientId=perf-producer-client] Received invalid metadata error in produce request on partition conduktorTopic-0 due to org.apache.kafka.common.errors.NotLeaderOrFollowerException: For requests intended only for the leader, this error indicates that the broker is not the current leader. For requests intended for any replica, this error indicates that the broker is not a replica of the topic partition.. Going to request metadata update now (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 14:15:18,584] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 121 on topic-partition conduktorTopic-0, retrying (2147483588 attempts left). Error: NOT_LEADER_OR_FOLLOWER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 14:15:18,584] WARN [Producer clientId=perf-producer-client] Received invalid metadata error in produce request on partition conduktorTopic-0 due to org.apache.kafka.common.errors.NotLeaderOrFollowerException: For requests intended only for the leader, this error indicates that the broker is not the current leader. For requests intended for any replica, this error indicates that the broker is not a replica of the topic partition.. Going to request metadata update now (org.apache.kafka.clients.producer.internals.Sender)
1 records sent, 0.2 records/sec (0.00 MB/sec), 6511.0 ms avg latency, 6511.0 ms max latency.
10 records sent, 1.531159 records/sec (0.00 MB/sec), 6010.20 ms avg latency, 6511.00 ms max latency, 6118 ms 50th, 6511 ms 95th, 6511 ms 99th, 6511 ms 99.9th.
type """docker-compose exec kafka-client \\
  curl \\
    --user 'admin:conduktor' \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/leader-election\"
"""
docker-compose exec kafka-client \
  curl \
    --user 'admin:conduktor' \
    --request DELETE "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/leader-election"
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
type """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic conduktorTopicRandomBytes
"""
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic conduktorTopicRandomBytes
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/random-bytes\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.chaos.ProduceSimulateMessageCorruptionPlugin\",
        \"priority\": 100,
        \"config\": { 
          \"topic\": \"conduktorTopicRandomBytes\",  
          \"sizeInBytes\": 10,
          \"rateInPercent\": 100
        }
    }'
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/random-bytes" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.chaos.ProduceSimulateMessageCorruptionPlugin",
        "priority": 100,
        "config": { 
          "topic": "conduktorTopicRandomBytes",  
          "sizeInBytes": 10,
          "rateInPercent": 100
        }
    }'
type """echo '{\"message\": \"hello world\"}' | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/gateway.properties \\
      --topic conduktorTopicRandomBytes
"""
echo '{"message": "hello world"}' | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
      --bootstrap-server conduktor-gateway:6969 \
      --producer.config /clientConfig/gateway.properties \
      --topic conduktorTopicRandomBytes
type """docker compose exec kafka-client \\
  kafka-console-consumer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --consumer.config /clientConfig/gateway.properties \\
      --from-beginning \\
      --topic conduktorTopicRandomBytes \\
      --max-messages 1
"""
docker compose exec kafka-client \
  kafka-console-consumer \
      --bootstrap-server conduktor-gateway:6969 \
      --consumer.config /clientConfig/gateway.properties \
      --from-beginning \
      --topic conduktorTopicRandomBytes \
      --max-messages 1
type """{\"message\": \"hello world\"}T[�   �X�{�
"""
{"message": "hello world"}T[�   �X�{�
type """docker-compose exec kafka-client \\
  curl \\
    --user 'admin:conduktor' \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/random-bytes\"
"""
docker-compose exec kafka-client \
  curl \
    --user 'admin:conduktor' \
    --request DELETE "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/random-bytes"
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-broker\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.chaos.SimulateSlowBrokerPlugin\",
        \"priority\": 100,
        \"config\": {
          \"rateInPercent\": 100,
          \"minLatencyMs\":100,
          \"maxLatencyMs\":1200
        }
    }'
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-broker" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateSlowBrokerPlugin",
        "priority": 100,
        "config": {
          "rateInPercent": 100,
          "minLatencyMs":100,
          "maxLatencyMs":1200
        }
    }'
type """docker-compose exec kafka-client \\
  kafka-producer-perf-test \\
    --producer.config /clientConfig/gateway.properties \\
    --record-size 100 \\
    --throughput 10 \\
    --num-records 10 \\
    --topic conduktorTopic
"""
docker-compose exec kafka-client \
  kafka-producer-perf-test \
    --producer.config /clientConfig/gateway.properties \
    --record-size 100 \
    --throughput 10 \
    --num-records 10 \
    --topic conduktorTopic
type """1 records sent, 0.1 records/sec (0.00 MB/sec), 7357.0 ms avg latency, 7357.0 ms max latency.
[2022-11-17 15:21:28,803] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 5 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:21:28,805] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 6 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:21:28,805] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 7 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:21:29,062] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 8 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
10 records sent, 0.066271 records/sec (0.00 MB/sec), 48360.70 ms avg latency, 120005.00 ms max latency, 2195 ms 50th, 120005 ms 95th, 120005 ms 99th, 120005 ms 99.9th.
"""
1 records sent, 0.1 records/sec (0.00 MB/sec), 7357.0 ms avg latency, 7357.0 ms max latency.
[2022-11-17 15:21:28,803] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 5 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:21:28,805] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 6 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:21:28,805] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 7 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:21:29,062] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 8 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
10 records sent, 0.066271 records/sec (0.00 MB/sec), 48360.70 ms avg latency, 120005.00 ms max latency, 2195 ms 50th, 120005 ms 95th, 120005 ms 99th, 120005 ms 99.9th.
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-broker\"
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request DELETE "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-broker"
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
type """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic conduktorTopicSlow
"""
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic conduktorTopicSlow
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-topic\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.chaos.SimulateSlowProducersConsumersPlugin\",
        \"priority\": 100,
        \"config\": {
          \"topic\": \"conduktorTopicSlow\",
          \"rateInPercent\": 100,
          \"minLatencyMs\":100,
          \"maxLatencyMs\":1200
        }
    }'
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-topic" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateSlowProducersConsumersPlugin",
        "priority": 100,
        "config": {
          "topic": "conduktorTopicSlow",
          "rateInPercent": 100,
          "minLatencyMs":100,
          "maxLatencyMs":1200
        }
    }'
type """docker-compose exec kafka-client \\
  kafka-producer-perf-test \\
      --producer.config /clientConfig/gateway.properties \\
      --record-size 100 \\
      --throughput 10 \\
      --num-records 10 \\
      --topic conduktorTopicSlow
"""
docker-compose exec kafka-client \
  kafka-producer-perf-test \
      --producer.config /clientConfig/gateway.properties \
      --record-size 100 \
      --throughput 10 \
      --num-records 10 \
      --topic conduktorTopicSlow
type """1 records sent, 0.1 records/sec (0.00 MB/sec), 7251.0 ms avg latency, 7251.0 ms max latency.
[2022-11-17 15:26:32,507] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 5 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:26:32,510] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 6 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:26:32,510] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 7 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:26:32,511] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 8 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
10 records sent, 1.354463 records/sec (0.00 MB/sec), 6830.00 ms avg latency, 7251.00 ms max latency, 6900 ms 50th, 7251 ms 95th, 7251 ms 99th, 7251 ms 99.9th.
"""
1 records sent, 0.1 records/sec (0.00 MB/sec), 7251.0 ms avg latency, 7251.0 ms max latency.
[2022-11-17 15:26:32,507] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 5 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:26:32,510] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 6 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:26:32,510] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 7 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:26:32,511] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 8 on topic-partition conduktorTopic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
10 records sent, 1.354463 records/sec (0.00 MB/sec), 6830.00 ms avg latency, 7251.00 ms max latency, 6900 ms 50th, 7251 ms 95th, 7251 ms 99th, 7251 ms 99.9th.
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-topic\"
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request DELETE "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-topic"
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
type """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic conduktorTopicSchema
"""
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic conduktorTopicSchema
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/invalid-schema\" \\
    --header 'Content-Type: application/json' \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.chaos.SimulateInvalidSchemaIdPlugin\",
        \"priority\": 100,
        \"config\": {
          \"topic\": \"conduktorTopicSchema\",
          \"invalidSchemaId\": 999,
          \"target\": \"CONSUME\"
        }
    }'
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/invalid-schema" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateInvalidSchemaIdPlugin",
        "priority": 100,
        "config": {
          "topic": "conduktorTopicSchema",
          "invalidSchemaId": 999,
          "target": "CONSUME"
        }
    }'
type """echo '{\"message\": \"hello world\"}' | \\
  docker compose exec -T schema-registry \\
    kafka-json-schema-console-producer \\
        --bootstrap-server conduktor-gateway:6969 \\
        --topic conduktorTopicSchema  \\
        --producer.config /clientConfig/gateway.properties \\
        --property value.schema='{ 
            \"title\": \"someSchema\", 
            \"type\": \"object\", 
            \"properties\": { 
              \"message\": { 
                \"type\": \"string\" 
              }
            }
          }'
"""
echo '{"message": "hello world"}' | \
  docker compose exec -T schema-registry \
    kafka-json-schema-console-producer \
        --bootstrap-server conduktor-gateway:6969 \
        --topic conduktorTopicSchema  \
        --producer.config /clientConfig/gateway.properties \
        --property value.schema='{ 
            "title": "someSchema", 
            "type": "object", 
            "properties": { 
              "message": { 
                "type": "string" 
              }
            }
          }'
type """docker-compose exec schema-registry \\
  kafka-json-schema-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --topic conduktorTopicSchema \\
    --consumer.config /clientConfig/gateway.properties \\
    --from-beginning 
"""
docker-compose exec schema-registry \
  kafka-json-schema-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --topic conduktorTopicSchema \
    --consumer.config /clientConfig/gateway.properties \
    --from-beginning 
type """Processed a total of 1 messages
[2022-11-17 15:59:13,184] ERROR Unknown error when running consumer:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.SerializationException: Error retrieving JSON schema for id 999
	at io.confluent.kafka.serializers.AbstractKafkaSchemaSerDe.toKafkaException(AbstractKafkaSchemaSerDe.java:259)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:182)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:130)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:103)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter.writeTo(JsonSchemaMessageFormatter.java:94)
	at io.confluent.kafka.formatter.SchemaMessageFormatter.writeTo(SchemaMessageFormatter.java:181)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:116)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:76)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:53)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Caused by: io.confluent.kafka.schemaregistry.client.rest.exceptions.RestClientException: Schema 999 not found; error code: 40403
	at io.confluent.kafka.schemaregistry.client.rest.RestService.sendHttpRequest(RestService.java:301)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.httpRequest(RestService.java:371)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.getId(RestService.java:840)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.getId(RestService.java:813)
	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.getSchemaByIdFromRegistry(CachedSchemaRegistryClient.java:294)
	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.getSchemaBySubjectAndId(CachedSchemaRegistryClient.java:417)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:119)
	... 8 more

"""
Processed a total of 1 messages
[2022-11-17 15:59:13,184] ERROR Unknown error when running consumer:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.SerializationException: Error retrieving JSON schema for id 999
	at io.confluent.kafka.serializers.AbstractKafkaSchemaSerDe.toKafkaException(AbstractKafkaSchemaSerDe.java:259)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:182)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:130)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:103)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter.writeTo(JsonSchemaMessageFormatter.java:94)
	at io.confluent.kafka.formatter.SchemaMessageFormatter.writeTo(SchemaMessageFormatter.java:181)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:116)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:76)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:53)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Caused by: io.confluent.kafka.schemaregistry.client.rest.exceptions.RestClientException: Schema 999 not found; error code: 40403
	at io.confluent.kafka.schemaregistry.client.rest.RestService.sendHttpRequest(RestService.java:301)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.httpRequest(RestService.java:371)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.getId(RestService.java:840)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.getId(RestService.java:813)
	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.getSchemaByIdFromRegistry(CachedSchemaRegistryClient.java:294)
	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.getSchemaBySubjectAndId(CachedSchemaRegistryClient.java:417)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:119)
	... 8 more

type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user 'admin:conduktor' \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/invalid-schema\"
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user 'admin:conduktor' \
    --request DELETE "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/invalid-schema"
type """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""
docker-compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
