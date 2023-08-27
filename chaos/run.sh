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

execute """cat clientConfig/gateway.properties
"""

execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic conduktorTopic
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
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/broken-broker\" \\
    --header \"Content-Type: application/json\" \\
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

execute """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request GET \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors\" \\
    --header \"Content-Type: application/json\" | jq
"""

execute """docker-compose exec kafka-client \\
  kafka-producer-perf-test \\
      --producer.config /clientConfig/gateway.properties \\
      --record-size 10 \\
      --throughput 10 \\
      --num-records 100 \\
      --topic conduktorTopic
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --user \"admin:conduktor\" \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/broken-broker\"
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""

execute """docker-compose exec kafka-client \\
  kafka-producer-perf-test \\
      --producer.config /clientConfig/gateway.properties \\
      --record-size 100 \\
      --throughput 10 \\
      --num-records 100 \\
      --topic conduktorTopic
"""

execute """52 records sent, 10.3 records/sec (0.00 MB/sec), 16.0 ms avg latency, 388.0 ms max latency.
100 records sent, 10.001000 records/sec (0.00 MB/sec), 10.69 ms avg latency, 388.00 ms max latency, 5 ms 50th, 43 ms 95th, 388 ms 99th, 388 ms 99.9th.
"""

execute """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic conduktorTopicDuplicate
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/duplicate-resource\" \\
    --header \"Content-Type: application/json\" \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.chaos.DuplicateResourcesPlugin\",
        \"priority\": 100,
        \"config\": {
            \"topic\": \"conduktorTopicDuplicate\",
            \"rateInPercent\": 100
        }
    }'
"""

execute """echo '{\"message\": \"hello world\"}' | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/gateway.properties \\
      --topic conduktorTopicDuplicate
"""

execute """docker-compose exec kafka-client \\
  kafka-console-consumer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --consumer.config /clientConfig/gateway.properties \\
      --from-beginning \\
      --topic conduktorTopicDuplicate \\
      --max-messages 2 | jq
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --user \"admin:conduktor\" \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/duplicate-resource\"
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/leader-election\" \\
    --header \"Content-Type: application/json\" \\
    --data-raw '{
        \"pluginClass\": \"io.conduktor.gateway.interceptor.chaos.SimulateLeaderElectionsErrorsPlugin\",
        \"priority\": 100,
        \"config\": {
          \"rateInPercent\": 50
        }
    }'
"""

execute """docker-compose exec kafka-client \\
  kafka-producer-perf-test \\
      --producer.config /clientConfig/gateway.properties \\
      --record-size 100 \\
      --throughput 10 \\
      --num-records 10 \\
      --topic conduktorTopic
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --user \"admin:conduktor\" \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/leader-election\"
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""

execute """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic conduktorTopicRandomBytes
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/random-bytes\" \\
    --header \"Content-Type: application/json\" \\
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

execute """echo '{\"message\": \"hello world\"}' | \\
  docker compose exec -T kafka-client \\
    kafka-console-producer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --producer.config /clientConfig/gateway.properties \\
      --topic conduktorTopicRandomBytes
"""

execute """docker compose exec kafka-client \\
  kafka-console-consumer \\
      --bootstrap-server conduktor-gateway:6969 \\
      --consumer.config /clientConfig/gateway.properties \\
      --from-beginning \\
      --topic conduktorTopicRandomBytes \\
      --max-messages 1
"""

execute """{\"message\": \"hello world\"}T[�   �X�{�
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --user \"admin:conduktor\" \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/random-bytes\"
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-broker\" \\
    --header \"Content-Type: application/json\" \\
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

execute """docker-compose exec kafka-client \\
  kafka-producer-perf-test \\
    --producer.config /clientConfig/gateway.properties \\
    --record-size 100 \\
    --throughput 10 \\
    --num-records 10 \\
    --topic conduktorTopic
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-broker\"
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""

execute """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic conduktorTopicSlow
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-topic\" \\
    --header \"Content-Type: application/json\" \\
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

execute """docker-compose exec kafka-client \\
  kafka-producer-perf-test \\
      --producer.config /clientConfig/gateway.properties \\
      --record-size 100 \\
      --throughput 10 \\
      --num-records 10 \\
      --topic conduktorTopicSlow
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/slow-topic\"
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""

execute """docker-compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server conduktor-gateway:6969 \\
    --command-config /clientConfig/gateway.properties \\
    --create --if-not-exists \\
    --topic conduktorTopicSchema
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/invalid-schema\" \\
    --header \"Content-Type: application/json\" \\
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

execute """echo '{\"message\": \"hello world\"}' | \\
  docker compose exec -T schema-registry \\
    kafka-json-schema-console-producer \\
        --bootstrap-server conduktor-gateway:6969 \\
        --topic conduktorTopicSchema \\
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

execute """docker-compose exec schema-registry \\
  kafka-json-schema-console-consumer \\
    --bootstrap-server conduktor-gateway:6969 \\
    --topic conduktorTopicSchema \\
    --consumer.config /clientConfig/gateway.properties \\
    --from-beginning
"""

execute """Processed a total of 1 messages
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

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request DELETE \"conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/invalid-schema\"
"""

execute """docker-compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptors | jq
"""

