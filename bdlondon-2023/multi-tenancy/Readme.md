# Multi-tenancy, virtual clusters



## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/8c3HOa5Sk1ZCuG5zwdMCaOX93.svg)](https://asciinema.org/a/8c3HOa5Sk1ZCuG5zwdMCaOX93)

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

## Listing topics in `kafka1`



```sh
kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `kafka1`](images/step-05-LIST_TOPICS.gif)

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
 

```

</details>

## Creating virtual cluster `london`

Creating virtual cluster `london` on gateway `gateway1`

```sh
token=$(curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/london/username/sa" \
    --header 'Content-Type: application/json' \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > london-sa.properties
```

<details>
  <summary>Realtime command output</summary>

  ![Creating virtual cluster `london`](images/step-06-CREATE_VIRTUAL_CLUSTERS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Creating virtual cluster `paris`

Creating virtual cluster `paris` on gateway `gateway1`

```sh
token=$(curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/paris/username/sa" \
    --header 'Content-Type: application/json' \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > paris-sa.properties
```

<details>
  <summary>Realtime command output</summary>

  ![Creating virtual cluster `paris`](images/step-07-CREATE_VIRTUAL_CLUSTERS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Creating topic `londonTopic`

Creating topic `londonTopic` on `london`
* topic `londonTopic` with partitions:1 replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config london-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic londonTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `londonTopic`](images/step-08-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic londonTopic.
 

```

</details>

## Creating topic `parisTopic`

Creating topic `parisTopic` on `paris`
* topic `parisTopic` with partitions:1 replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config paris-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic parisTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `parisTopic`](images/step-09-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic parisTopic.
 

```

</details>

## Listing topics in `london`



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config london-sa.properties \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `london`](images/step-10-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
londonTopic
 

```

</details>

## Listing topics in `paris`



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config paris-sa.properties \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `paris`](images/step-11-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
parisTopic
 

```

</details>

## Producing 1message in `londonTopic`

Producing 1 message in `londonTopic` in cluster `london`

```sh
echo '{"message: "Hello from London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config london-sa.properties \
        --topic londonTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Producing 1message in `londonTopic`](images/step-12-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Consuming from `londonTopic`

Consuming from `londonTopic` in cluster `london

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic londonTopic \
    --from-beginning \
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `londonTopic`](images/step-13-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Producing 1message in `parisTopic`

Producing 1 message in `parisTopic` in cluster `paris`

```sh
echo '{"message: "Bonjour depuis Paris"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config paris-sa.properties \
        --topic parisTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Producing 1message in `parisTopic`](images/step-14-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Consuming from `parisTopic`

Consuming from `parisTopic` in cluster `paris

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config paris-sa.properties \
    --topic parisTopic \
    --from-beginning \
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `parisTopic`](images/step-15-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Creating topic `existingLondonTopic`

Creating topic `existingLondonTopic` on `kafka1`
* topic `existingLondonTopic` with partitions:1 replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic existingLondonTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `existingLondonTopic`](images/step-16-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic existingLondonTopic.
 

```

</details>

## Producing 1message in `existingLondonTopic`

Producing 1 message in `existingLondonTopic` in cluster `kafka1`

```sh
echo '{"message: "Hello from London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
        --topic existingLondonTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Producing 1message in `existingLondonTopic`](images/step-17-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## 



```sh
curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/admin/vclusters/v1/vcluster/london/topics/existingLondonTopic \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "physicalTopicName": "existingLondonTopic",
      "readOnly": false,
      "concentrated": false
    }' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![](images/step-18-SH.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "logicalTopicName": "existingLondonTopic",
  "physicalTopicName": "existingLondonTopic",
  "readOnly": false,
  "concentrated": false
}
 

```

</details>

## Listing topics in `london`



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config london-sa.properties \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `london`](images/step-19-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
existingLondonTopic
londonTopic
 

```

</details>

## Creating topic `existingSharedTopic`

Creating topic `existingSharedTopic` on `kafka1`
* topic `existingSharedTopic` with partitions:1 replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic existingSharedTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `existingSharedTopic`](images/step-20-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic existingSharedTopic.
 

```

</details>

## Producing 1message in `existingSharedTopic`

Producing 1 message in `existingSharedTopic` in cluster `kafka1`

```sh
echo '{"message": "Existing shared message"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
        --topic existingSharedTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Producing 1message in `existingSharedTopic`](images/step-21-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## 



```sh
curl \
  --silent \
  --request POST localhost:8888/admin/vclusters/v1/vcluster/london/topics/existingSharedTopic \
  --user admin:conduktor \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "physicalTopicName": "existingSharedTopic",
    "readOnly": false,
    "concentrated": false
  }' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![](images/step-22-SH.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "logicalTopicName": "existingSharedTopic",
  "physicalTopicName": "existingSharedTopic",
  "readOnly": false,
  "concentrated": false
}
 

```

</details>

## Listing topics in `london`



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config london-sa.properties \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `london`](images/step-23-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
existingLondonTopic
existingSharedTopic
londonTopic
 

```

</details>

## Consuming from `existingLondonTopic`

Consuming from `existingLondonTopic` in cluster `london

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic existingLondonTopic \
    --from-beginning \
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `existingLondonTopic`](images/step-24-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Consuming from `existingSharedTopic`

Consuming from `existingSharedTopic` in cluster `london

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `existingSharedTopic`](images/step-25-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "Existing shared message"
}
 

```

</details>

## 



```sh
curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/admin/vclusters/v1/vcluster/paris/topics/existingSharedTopic \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "physicalTopicName": "existingSharedTopic",
    "readOnly": false,
    "concentrated": false
  }' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![](images/step-26-SH.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "logicalTopicName": "existingSharedTopic",
  "physicalTopicName": "existingSharedTopic",
  "readOnly": false,
  "concentrated": false
}
 

```

</details>

## Listing topics in `paris`



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config paris-sa.properties \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `paris`](images/step-27-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
existingSharedTopic
parisTopic
 

```

</details>

## Consuming from `existingSharedTopic`

Consuming from `existingSharedTopic` in cluster `paris

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config paris-sa.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `existingSharedTopic`](images/step-28-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "Existing shared message"
}
 

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

  ![Cleanup the docker environment](images/step-29-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

# Conclusion

Multi-tenancy/Virtual clusters is key to be in control of your kafka spend!

