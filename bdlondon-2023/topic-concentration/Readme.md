# Infinite Partitions with Topic Concentration

Conduktor Gateway's topic concentration feature allows you to store multiple topics's data on a single underlying Kafka topic. 

To clients, it appears that there are multiple topics and these can be read from as normal but in the underlying Kafka cluster there is a lot less resource required.

In this demo we are going to create a concentrated topic for powering several virtual topics. 

Create the virtual topics, produce and consume data to them, and explore how this works.

## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/ChuQj19vMFCswItp5XdT71ocr.svg)](https://asciinema.org/a/ChuQj19vMFCswItp5XdT71ocr)

### Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A main 3 nodes Kafka cluster
* A 2 nodes Conduktor Gateway server

```sh
cat docker-compose.yaml
```

<details>
  <summary>File content</summary>

```yaml
version: '3.7'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    hostname: zookeeper
    container_name: zookeeper
    ports:
    - 2801:2801
    environment:
      ZOOKEEPER_CLIENT_PORT: 2801
      ZOOKEEPER_TICK_TIME: 2000
    healthcheck:
      test: nc -zv 0.0.0.0 2801 || exit 1
      interval: 5s
      retries: 25
  kafka1:
    hostname: kafka1
    container_name: kafka1
    image: confluentinc/cp-kafka:latest
    ports:
    - 29092:29092
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:29092,INTERNAL://:9092
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka1:9092,EXTERNAL_SAME_HOST://localhost:29092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper:
        condition: service_healthy
    healthcheck:
      test: nc -zv kafka1 9092 || exit 1
      interval: 5s
      retries: 25
  kafka2:
    hostname: kafka2
    container_name: kafka2
    image: confluentinc/cp-kafka:latest
    ports:
    - 29093:29093
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:29093,INTERNAL://:9093
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka2:9093,EXTERNAL_SAME_HOST://localhost:29093
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper:
        condition: service_healthy
    healthcheck:
      test: nc -zv kafka2 9093 || exit 1
      interval: 5s
      retries: 25
  kafka3:
    image: confluentinc/cp-kafka:latest
    hostname: kafka3
    container_name: kafka3
    ports:
    - 29094:29094
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:29094,INTERNAL://:9094
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka3:9094,EXTERNAL_SAME_HOST://localhost:29094
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper:
        condition: service_healthy
    healthcheck:
      test: nc -zv kafka3 9094 || exit 1
      interval: 5s
      retries: 25
  schema-registry:
    image: confluentinc/cp-schema-registry:latest
    hostname: schema-registry
    container_name: schema-registry
    ports:
    - 8081:8081
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      SCHEMA_REGISTRY_LOG4J_ROOT_LOGLEVEL: WARN
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
      SCHEMA_REGISTRY_KAFKASTORE_TOPIC: _schemas
      SCHEMA_REGISTRY_SCHEMA_REGISTRY_GROUP_ID: schema-registry
    volumes:
    - type: bind
      source: .
      target: /clientConfig
      read_only: true
    depends_on:
      kafka1:
        condition: service_healthy
      kafka2:
        condition: service_healthy
      kafka3:
        condition: service_healthy
    healthcheck:
      test: nc -zv schema-registry 8081 || exit 1
      interval: 5s
      retries: 25
  gateway1:
    image: conduktor/conduktor-gateway:2.1.4
    hostname: gateway1
    container_name: gateway1
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
    depends_on:
      kafka1:
        condition: service_healthy
      kafka2:
        condition: service_healthy
      kafka3:
        condition: service_healthy
    ports:
    - 6969:6969
    - 6970:6970
    - 6971:6971
    - 8888:8888
    healthcheck:
      test: curl localhost:8888/health
      interval: 5s
      retries: 25
  gateway2:
    image: conduktor/conduktor-gateway:2.1.4
    hostname: gateway2
    container_name: gateway2
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_START_PORT: 7969
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
    depends_on:
      kafka1:
        condition: service_healthy
      kafka2:
        condition: service_healthy
      kafka3:
        condition: service_healthy
    ports:
    - 7969:7969
    - 7970:7970
    - 7971:7971
    - 8889:8888
    healthcheck:
      test: curl localhost:8888/health
      interval: 5s
      retries: 25
  cli-kcat:
    hostname: cli-kcat
    container_name: cli-kcat
    image: confluentinc/cp-kcat:latest
    entrypoint: sleep 100d
    volumes:
    - type: bind
      source: .
      target: /clientConfig
      read_only: true
  ksqldb-server:
    image: confluentinc/ksqldb-server:0.29.0
    hostname: ksqldb-server
    container_name: ksqldb-server
    network_mode: host
    profiles:
    - ksqldb
    depends_on:
      kafka1:
        condition: service_healthy
      kafka2:
        condition: service_healthy
      kafka3:
        condition: service_healthy
    ports:
    - 8088:8088
    healthcheck:
      test: curl localhost:8088/health
      interval: 5s
      retries: 25
    environment:
      KSQL_LISTENERS: http://0.0.0.0:8088
      KSQL_BOOTSTRAP_SERVERS: ${BOOTSTRAP_SERVERS:-}
      KSQL_SECURITY_PROTOCOL: ${SECURITY_PROTOCOL:-}
      KSQL_SASL_MECHANISM: ${SASL_MECHANISM:-}
      KSQL_SASL_JAAS_CONFIG: ${SASL_JAAS_CONFIG:-}
      KSQL_KSQL_LOGGING_PROCESSING_STREAM_AUTO_CREATE: 'true'
      KSQL_KSQL_LOGGING_PROCESSING_TOPIC_AUTO_CREATE: 'true'
  ksqldb-cli:
    image: confluentinc/ksqldb-cli:0.29.0
    container_name: ksqldb-cli
    profiles:
    - ksqldb
    depends_on:
      ksqldb-server:
        condition: service_healthy
    entrypoint: /bin/sh
    tty: 'true'
networks:
  demo: null
```

</details>

## Startup the docker environment

Start all your docker processes, wait for them to be up and ready, then run in background

* `--wait`: Wait for services to be `running|healthy`. Implies detached mode.
* `--detach`: Detached mode: Run containers in the background

```sh
docker compose up --detach --wait
```

<details>
  <summary>Realtime command output</summary>

  ![Startup the docker environment](images/step-04-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Creating virtual cluster `teamA`

Creating virtual cluster `teamA` on gateway `gateway1`

```sh
token=$(curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa" \
    --header 'Content-Type: application/json' \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > teamA-sa.properties
```

<details>
  <summary>Realtime command output</summary>

  ![Creating virtual cluster `teamA`](images/step-05-CREATE_VIRTUAL_CLUSTERS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

### Review the kafka properties to connect to `teamA`



```sh
cat teamA-sa.properties
```

<details on>
  <summary>File content</summary>

```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcwMjk3Njg3M30.qeLJoln-ELte8d5Kyc36VeRMm6X_RSZHIrgD3y9tHCk';
bootstrap.servers=localhost:6969
```

</details>

## Create the topic that will hold virtual topics

Creating topic `hold-many-concentrated-topics` on `kafka1`
* topic `hold-many-concentrated-topics` with partitions:5 replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --replication-factor 1 \
    --partitions 5 \
    --create --if-not-exists \
    --topic hold-many-concentrated-topics
```

<details>
  <summary>Realtime command output</summary>

  ![Create the topic that will hold virtual topics](images/step-07-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic hold-many-concentrated-topics.
 

```

</details>

## Creating mapping from `concentrated-.*` to `hold-many-concentrated-topics`

Let's tell the `gateway1` that topic matching the pattern `concentrated-.*` need to be concentrated into the underlying `hold-many-concentrated-topics` physical topic.

> [!NOTE]
> You don’t need to create the physical topic that backs the concentrated topics, it will automatically be created when a client topic starts using the concentrated topic.

```sh
curl \
    --silent \
    --user "admin:conduktor" \
    --request POST 'http://localhost:8888/admin/vclusters/v1/vcluster/teamA/topics/concentrated-.%2A' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "physicalTopicName": "hold-many-concentrated-topics",
        "readOnly": false,
        "concentrated": true
    }' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Creating mapping from `concentrated-.*` to `hold-many-concentrated-topics`](images/step-08-ADD_TOPIC_MAPPING.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "logicalTopicName": "concentrated-.*",
  "physicalTopicName": "hold-many-concentrated-topics",
  "readOnly": false,
  "concentrated": true
}
 

```

</details>

## Create concentrated topics

Creating topics `concentrated-normal,concentrated-delete,concentrated-compact,concentrated-delete-compact,concentrated-compact-delete,concentrated-small-retention,concentrated-large-retention` on `teamA`
* topic `concentrated-normal` with partitions:1 replication-factor:1* topic `concentrated-delete` with partitions:1 replication-factor:1* topic `concentrated-compact` with partitions:1 replication-factor:1* topic `concentrated-delete-compact` with partitions:1 replication-factor:1* topic `concentrated-compact-delete` with partitions:1 replication-factor:1* topic `concentrated-small-retention` with partitions:1 replication-factor:1* topic `concentrated-large-retention` with partitions:1 replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic concentrated-normal
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config cleanup.policy=delete \
    --create --if-not-exists \
    --topic concentrated-delete
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config cleanup.policy=compact \
    --create --if-not-exists \
    --topic concentrated-compact
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config cleanup.policy=delete,compact \
    --create --if-not-exists \
    --topic concentrated-delete-compact
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config cleanup.policy=compact,delete \
    --create --if-not-exists \
    --topic concentrated-compact-delete
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config retention.ms=10000 \
    --create --if-not-exists \
    --topic concentrated-small-retention
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config retention.ms=6048000000 \
    --create --if-not-exists \
    --topic concentrated-large-retention
```

<details>
  <summary>Realtime command output</summary>

  ![Create concentrated topics](images/step-09-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic concentrated-normal.
Created topic concentrated-delete.
Created topic concentrated-compact.
Created topic concentrated-delete-compact.
Created topic concentrated-compact-delete.
Created topic concentrated-small-retention.
Created topic concentrated-large-retention.
 

```

</details>

## Assert the topics have been created



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Assert the topics have been created](images/step-10-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
concentrated-compact
concentrated-compact-delete
concentrated-delete
concentrated-delete-compact
concentrated-large-retention
concentrated-normal
concentrated-small-retention
 

```

</details>

## Assert the topics have not been created in the underlying kafka cluster

If we list topics from the backend cluster, not from Gateway perspective, we do not see the concentrated topics.

```sh
kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Assert the topics have not been created in the underlying kafka cluster](images/step-11-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
__consumer_offsets
_acls
_auditLogs
_consumerGroupSubscriptionBackingTopic
_interceptorConfigs
_license
_offsetStore
_schemas
_topicMappings
_topicRegistry
hold-many-concentrated-topics
hold-many-concentrated-topics_compacted
hold-many-concentrated-topics_compactedAndDeleted
 

```

</details>

## Let's continue created virtual topics, but now with many partitions

Creating topics `concentrated-topic-with-10-partitions,concentrated-topic-with-100-partitions` on `teamA`
* topic `concentrated-topic-with-10-partitions` with partitions:10 replication-factor:1* topic `concentrated-topic-with-100-partitions` with partitions:100 replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 10 \
    --create --if-not-exists \
    --topic concentrated-topic-with-10-partitions
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 100 \
    --create --if-not-exists \
    --topic concentrated-topic-with-100-partitions
```

<details>
  <summary>Realtime command output</summary>

  ![Let's continue created virtual topics, but now with many partitions](images/step-12-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic concentrated-topic-with-10-partitions.
Created topic concentrated-topic-with-100-partitions.
 

```

</details>

## Assert they exist in `teamA` cluster



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Assert they exist in `teamA` cluster](images/step-13-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
concentrated-compact
concentrated-compact-delete
concentrated-delete
concentrated-delete-compact
concentrated-large-retention
concentrated-normal
concentrated-small-retention
concentrated-topic-with-10-partitions
concentrated-topic-with-100-partitions
 

```

</details>

## Producing 1message in `concentrated-topic-with-10-partitions`

Producing 1 message in `concentrated-topic-with-10-partitions` in cluster `teamA`

```sh
echo '{"type": "Sports", "price": 75, "color": "blue"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic concentrated-topic-with-10-partitions
```

<details>
  <summary>Realtime command output</summary>

  ![Producing 1message in `concentrated-topic-with-10-partitions`](images/step-14-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Consuming from `concentrated-topic-with-10-partitions`

Consuming from `concentrated-topic-with-10-partitions` in cluster `teamA

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic concentrated-topic-with-10-partitions \
    --from-beginning \
    --timeout-ms 5000 \
    --property print.headers=true
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `concentrated-topic-with-10-partitions`](images/step-15-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
PDK_originalPartition:5,PDK_originalTopic:concentrated-topic-with-10-partitions	{"type": "Sports", "price": 75, "color": "blue"}
 

```

</details>

## Producing 1message in `concentrated-topic-with-100-partitions`

Producing 1 message in `concentrated-topic-with-100-partitions` in cluster `teamA`

```sh
echo '{"msg":"hello world"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic concentrated-topic-with-100-partitions
```

<details>
  <summary>Realtime command output</summary>

  ![Producing 1message in `concentrated-topic-with-100-partitions`](images/step-16-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Consuming from `concentrated-topic-with-100-partitions`

Consuming from `concentrated-topic-with-100-partitions` in cluster `teamA

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic concentrated-topic-with-100-partitions \
    --from-beginning \
    --timeout-ms 5000 \
    --property print.headers=true
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `concentrated-topic-with-100-partitions`](images/step-17-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
PDK_originalPartition:89,PDK_originalTopic:concentrated-topic-with-100-partitions	{"msg":"hello world"}
 

```

</details>

## Cleanup the docker environment

Remove all your docker processes and associated volumes

* `--volumes`: Remove named volumes declared in the "volumes" section of the Compose file and anonymous volumes attached to containers.

```sh
docker compose down --volumes
```

<details>
  <summary>Realtime command output</summary>

  ![Cleanup the docker environment](images/step-19-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

# Conclusion

Infinite partitions with topic concentration is really a game changer!

