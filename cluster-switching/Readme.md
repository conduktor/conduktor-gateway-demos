# What is cluster switching?

Conduktor Gateway's cluster switching allows hot-switch the backend Kafka cluster without having to change your client configuration, or restart Gateway.

This features enables you to build a seamless disaster recovery strategy for your Kafka cluster, when Gateway is deployed in combination with a replication solution (like MirrorMaker, Confluent replicator, Cluster Linking, etc.).

## Limitations to consider when designing a disaster recovery strategy

* Cluster switching does not replicate data between clusters. You need to use a replication solution like MirrorMaker to replicate data between clusters
* Because of their asynchronous nature, such replication solutions may lead to data loss in case of a disaster
* Cluster switching is a manual process - automatic failover is not supported, yet
* Concentrated topics offsets: Gateway stores client offsets of concentrated topics in a regular Kafka topic. When replicating this topic, there will be no adjustments of potential offsets shifts between the source and failover cluster
* When switching, Kafka consumers will perform a group rebalance. They will not be able to commit their offset before the rebalance. This may lead to a some messages being consumed twice

### Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A main 3 node Kafka cluster
* A failover 3 node Kafka cluster
* A 2 node Conduktor Gateway server
* A MirrorMaker container

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
    hostname: gateway1
    container_name: gateway1
    image: conduktor/conduktor-gateway:2.1.4
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_CLUSTER_ID: private
      GATEWAY_BACKEND_KAFKA_SELECTOR: 'file : { path:  /config/clusters.yaml}'
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
    volumes:
    - type: bind
      source: .
      target: /config
      read_only: true
  gateway2:
    hostname: gateway2
    container_name: gateway2
    image: conduktor/conduktor-gateway:2.1.4
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_START_PORT: 7969
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_CLUSTER_ID: private
      GATEWAY_BACKEND_KAFKA_SELECTOR: 'file : { path:  /config/clusters.yaml}'
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
    volumes:
    - type: bind
      source: .
      target: /config
      read_only: true
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
  failover-kafka1:
    image: confluentinc/cp-kafka:latest
    healthcheck:
      test: nc -zv failover-kafka1 9092 || exit 1
      interval: 5s
      retries: 25
    hostname: failover-kafka1
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801/backup
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:39092,INTERNAL://:9092
      KAFKA_ADVERTISED_LISTENERS: EXTERNAL_SAME_HOST://localhost:39092,INTERNAL://failover-kafka1:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper:
        condition: service_healthy
    container_name: failover-kafka1
    ports:
    - 39092:39092
  failover-kafka2:
    image: confluentinc/cp-kafka:latest
    healthcheck:
      test: nc -zv failover-kafka2 9093 || exit 1
      interval: 5s
      retries: 25
    hostname: failover-kafka2
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801/backup
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:39093,INTERNAL://:9093
      KAFKA_ADVERTISED_LISTENERS: EXTERNAL_SAME_HOST://localhost:39093,INTERNAL://failover-kafka2:9093
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper:
        condition: service_healthy
    container_name: failover-kafka2
    ports:
    - 39093:39093
  failover-kafka3:
    image: confluentinc/cp-kafka:latest
    healthcheck:
      test: nc -zv failover-kafka3 9094 || exit 1
      interval: 5s
      retries: 25
    hostname: failover-kafka3
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801/backup
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:39094,INTERNAL://:9094
      KAFKA_ADVERTISED_LISTENERS: EXTERNAL_SAME_HOST://localhost:39094,INTERNAL://failover-kafka3:9094
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper:
        condition: service_healthy
    container_name: failover-kafka3
    ports:
    - 39094:39094
  mirror-maker:
    image: confluentinc/cp-kafka:latest
    healthcheck:
      test: nc -zv failover-kafka3 9094 || exit 1
      interval: 5s
      retries: 25
    hostname: mirror-maker
    depends_on:
      kafka1:
        condition: service_healthy
      kafka2:
        condition: service_healthy
      kafka3:
        condition: service_healthy
      failover-kafka1:
        condition: service_healthy
      failover-kafka2:
        condition: service_healthy
      failover-kafka3:
        condition: service_healthy
    container_name: mirror-maker
    volumes:
    - type: bind
      source: .
      target: /config
      read_only: true
    command: connect-mirror-maker /config/mm2.properties
networks:
  demo: null
```

</details>

### Review the Gateway configuration

The Kafka brokers used by Gateway are stored in `clusters.yaml` and this is mounted into the Gateway container. 
The failover cluster is configured with the `gateway.role` property set to `failover`. 
This cluster is not used by Gateway in normal mode.

```sh
cat clusters.yaml
```

<details on>
  <summary>File content</summary>

```yaml
config:
  main:
    bootstrap.servers: kafka1:9092,kafka2:9093,kafka3:9094

  failover:
    bootstrap.servers: failover-kafka1:9092,failover-kafka2:9093,failover-kafka3:9094
    gateway.roles: failover
```

</details>

### Review the Mirror-Maker configuration

MirrorMaker is configured to replicate all topics and groups from the main cluster to the failover cluster (see `mm2.properties`).

One important bit is the `replication.policy.class=org.apache.kafka.connect.mirror.IdentityReplicationPolicy` configuration. 

Gateway expects the topics to have the same names on both clusters.

```sh
cat mm2.properties
```

<details>
  <summary>File content</summary>

```properties
# specify any number of cluster aliases
clusters = A, B

# connection information for each cluster
A.bootstrap.servers = kafka1:9092,kafka2:9093,kafka3:9094
B.bootstrap.servers = failover-kafka1:9092,failover-kafka2:9093,failover-kafka3:9094

# enable and configure individual replication flows
A->B.enabled = true
# Do not rename topics
replication.policy.class=org.apache.kafka.connect.mirror.IdentityReplicationPolicy

# regex which defines which topics gets replicated.
A->B.topics = .*
refresh.topics.interval.seconds=10
A.consumer.auto.offset.reset=earliest

# regex which defines which consumer groups gets replicated.
A->B.groups = .*
sync.group.offsets.enabled=true
refresh.groups.interval.seconds=10

# Setting replication factor of newly created remote topics
replication.factor=1

############################# Internal Topic Settings  #############################
# The replication factor for mm2 internal topics "heartbeats", "B.checkpoints.internal" and "mm2-offset-syncs.B.internal"
# For anything other than development testing, a value greater than 1 is recommended to ensure availability, such as 3.
checkpoints.topic.replication.factor=1
heartbeats.topic.replication.factor=1
offset-syncs.topic.replication.factor=1

# The replication factor for connect internal topics "mm2-configs.B.internal", "mm2-offsets.B.internal" and
# "mm2-status.B.internal"
# For anything other than development testing, a value greater than 1 is recommended to ensure availability such as 3.
offset.storage.replication.factor=1
status.storage.replication.factor=1
config.storage.replication.factor=1
```

</details>

## Start the docker environment

Start the environment with

```sh
docker compose up -d --wait
```

<details>
  <summary>Realtime command output</summary>

  ![Start the docker environment](images/step-06-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ docker compose up -d --wait
 Network cluster-switching_default  Creating
 Network cluster-switching_default  Created
 Container zookeeper  Creating
 Container cli-kcat  Creating
 Container cli-kcat  Created
 Container zookeeper  Created
 Container failover-kafka3  Creating
 Container kafka1  Creating
 Container failover-kafka1  Creating
 Container failover-kafka2  Creating
 Container kafka2  Creating
 Container kafka3  Creating
 Container kafka1  Created
 Container failover-kafka2  Created
 Container failover-kafka3  Created
 Container kafka3  Created
 Container kafka2  Created
 Container schema-registry  Creating
 Container gateway1  Creating
 Container gateway2  Creating
 Container failover-kafka1  Created
 Container mirror-maker  Creating
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway2  Created
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway1  Created
 Container schema-registry  Created
 Container mirror-maker  Created
 Container zookeeper  Starting
 Container cli-kcat  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container cli-kcat  Started
 Container zookeeper  Healthy
 Container failover-kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container failover-kafka3  Starting
 Container zookeeper  Healthy
 Container zookeeper  Healthy
 Container failover-kafka2  Starting
 Container kafka1  Starting
 Container kafka3  Started
 Container failover-kafka1  Started
 Container kafka2  Started
 Container kafka1  Started
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container failover-kafka2  Started
 Container failover-kafka3  Started
 Container failover-kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container failover-kafka1  Waiting
 Container failover-kafka2  Waiting
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container gateway2  Starting
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container gateway1  Starting
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container schema-registry  Starting
 Container kafka1  Healthy
 Container failover-kafka1  Healthy
 Container kafka2  Healthy
 Container failover-kafka2  Healthy
 Container failover-kafka3  Healthy
 Container mirror-maker  Starting
 Container schema-registry  Started
 Container gateway1  Started
 Container mirror-maker  Started
 Container gateway2  Started
 Container mirror-maker  Waiting
 Container gateway1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container failover-kafka3  Waiting
 Container schema-registry  Waiting
 Container cli-kcat  Waiting
 Container failover-kafka2  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container gateway2  Waiting
 Container failover-kafka1  Waiting
 Container cli-kcat  Healthy
 Container zookeeper  Healthy
 Container failover-kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container failover-kafka2  Healthy
 Container kafka3  Healthy
 Container failover-kafka1  Healthy
 Container mirror-maker  Healthy
 Container schema-registry  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy

```

</details>

## Create teamA virtual cluster



```sh
token=$(curl \
    --silent \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa" \
    --user 'admin:conduktor' \
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

  ![Create teamA virtual cluster](images/step-07-CREATE_VIRTUAL_CLUSTERS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
++ curl --silent --request POST http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa --user admin:conduktor --header 'Content-Type: application/json' --data-raw '{"lifeTimeSeconds": 7776000}'
++ jq -r .token
+ token=eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcwMjgxMDY0OH0.veYVo6aO5s9FavpGNhw6LNYKqkyDFp1tOlRABjIFwek
+ echo '
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='\''sa'\'' password='\''eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcwMjgxMDY0OH0.veYVo6aO5s9FavpGNhw6LNYKqkyDFp1tOlRABjIFwek'\'';
'

```

</details>

### Review the kafka properties to connect to teamA



```sh
cat teamA-sa.properties
```

<details on>
  <summary>File content</summary>

```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcwMjgxMDUxMH0.Zr_XISAvoLv-daXPWeK7IkK5oC4kjzPdBwMGHSd2-e0';
bootstrap.servers=localhost:6969
```

</details>

## Create topic users



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic users
```

<details>
  <summary>Realtime command output</summary>

  ![Create topic users](images/step-09-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-topics --bootstrap-server localhost:6969 --command-config teamA-sa.properties --replication-factor 1 --partitions 1 --create --if-not-exists --topic users
Created topic users.

```

</details>

## Send tom and florent into topic users



```sh
echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users

echo '{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users
```

<details>
  <summary>Realtime command output</summary>

  ![Send tom and florent into topic users](images/step-10-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}'
+ kafka-console-producer --bootstrap-server localhost:6969 --producer.config teamA-sa.properties --topic users
+ echo '{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}'
+ kafka-console-producer --bootstrap-server localhost:6969 --producer.config teamA-sa.properties --topic users

```

</details>

## 



```sh
kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![](images/step-11-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-topics --bootstrap-server localhost:29092,localhost:29093,localhost:29094 --list
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
heartbeats
mm2-configs.B.internal
mm2-offset-syncs.B.internal
mm2-offsets.B.internal
mm2-status.B.internal
teamAusers

```

</details>

## Wait for mirror maker to do its job on gateway internal topic



```sh
kafka-console-consumer \
    --bootstrap-server localhost:39092,localhost:39093,localhost:39094 \
    --topic _topicMappings \
    --from-beginning \
    --max-messages 1 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Wait for mirror maker to do its job on gateway internal topic](images/step-12-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-console-consumer --bootstrap-server localhost:39092,localhost:39093,localhost:39094 --topic _topicMappings --from-beginning --max-messages 1
+ jq
Processed a total of 1 messages
{
  "users": {
    "clusterId": "main",
    "name": "teamAusers",
    "isConcentrated": false,
    "compactedName": "teamAusers",
    "isCompacted": false,
    "compactedAndDeletedName": "teamAusers",
    "isCompactedAndDeleted": false,
    "createdAt": [
      2023,
      9,
      18,
      10,
      57,
      33,
      299
    ],
    "isDeleted": false,
    "configuration": {
      "numPartitions": 1,
      "replicationFactor": 1,
      "properties": {}
    },
    "isVirtual": false
  }
}

```

</details>

## Wait for mirror maker to do its job on user topics



```sh
kafka-console-consumer \
    --bootstrap-server localhost:39092,localhost:39093,localhost:39094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 1 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Wait for mirror maker to do its job on user topics](images/step-13-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-console-consumer --bootstrap-server localhost:39092,localhost:39093,localhost:39094 --topic teamAusers --from-beginning --max-messages 1
+ jq
Processed a total of 1 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
}

```

</details>

## Assert mirror maker did its job



```sh
kafka-topics \
    --bootstrap-server localhost:39092,localhost:39093,localhost:39094 \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Assert mirror maker did its job](images/step-14-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-topics --bootstrap-server localhost:39092,localhost:39093,localhost:39094 --list
A.checkpoints.internal
A.heartbeats
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
heartbeats
mm2-configs.A.internal
mm2-offsets.A.internal
mm2-status.A.internal
teamAusers

```

</details>

## Call the failover switch api on gateway1



```sh
curl \
  --silent \
  --user "admin:conduktor" \
  --request POST 'http://localhost:8888/admin/pclusters/v1/pcluster/main/switch?to=failover' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Call the failover switch api on gateway1](images/step-15-FAILOVER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ curl --silent --user admin:conduktor --request POST 'http://localhost:8888/admin/pclusters/v1/pcluster/main/switch?to=failover'
+ jq
{
  "message": "Cluster switched"
}

```

</details>

## Call the failover switch api on gateway2



```sh
curl \
  --silent \
  --user "admin:conduktor" \
  --request POST 'http://localhost:8889/admin/pclusters/v1/pcluster/main/switch?to=failover' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Call the failover switch api on gateway2](images/step-16-FAILOVER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ curl --silent --user admin:conduktor --request POST 'http://localhost:8889/admin/pclusters/v1/pcluster/main/switch?to=failover'
+ jq
{
  "message": "Cluster switched"
}

```

</details>

## Produce thibault into users, it should hit only failover-kafka



```sh
echo '{"name":"thibaut","username":"thibaut@conduktor.io","password":"youpi","visa":"#812SSS","address":"Les ifs"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users
```

<details>
  <summary>Realtime command output</summary>

  ![Produce thibault into users, it should hit only failover-kafka](images/step-17-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ echo '{"name":"thibaut","username":"thibaut@conduktor.io","password":"youpi","visa":"#812SSS","address":"Les ifs"}'
+ kafka-console-producer --bootstrap-server localhost:6969 --producer.config teamA-sa.properties --topic users

```

</details>

## Verify we can read florent, and tom (via mirror maker) and thibault (via switch)



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Verify we can read florent, and tom (via mirror maker) and thibault (via switch)](images/step-18-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-console-consumer --bootstrap-server localhost:6969 --consumer.config teamA-sa.properties --topic users --from-beginning --max-messages 3 --timeout-ms 5000
+ jq
Processed a total of 3 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ",
  "address": "Dubai, UAE"
}
{
  "name": "thibaut",
  "username": "thibaut@conduktor.io",
  "password": "youpi",
  "visa": "#812SSS",
  "address": "Les ifs"
}

```

</details>

## Verify thibaut is not in main kafka



```sh
kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic teamAusers \
    --from-beginning \
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Verify thibaut is not in main kafka](images/step-19-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-console-consumer --bootstrap-server localhost:29092,localhost:29093,localhost:29094 --topic teamAusers --from-beginning --timeout-ms 5000
+ jq
[2023-09-18 11:58:31,244] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ",
  "address": "Dubai, UAE"
}

```

</details>

## Verify thibaut is in failover



```sh
kafka-console-consumer \
    --bootstrap-server localhost:39092,localhost:39093,localhost:39094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 3 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Verify thibaut is in failover](images/step-20-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-console-consumer --bootstrap-server localhost:39092,localhost:39093,localhost:39094 --topic teamAusers --from-beginning --max-messages 3
+ jq
Processed a total of 3 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ",
  "address": "Dubai, UAE"
}
{
  "name": "thibaut",
  "username": "thibaut@conduktor.io",
  "password": "youpi",
  "visa": "#812SSS",
  "address": "Les ifs"
}

```

</details>

## Cleanup the docker environment

Remove all components from docker

```sh
docker compose down -v
```

<details>
  <summary>Realtime command output</summary>

  ![Cleanup the docker environment](images/step-21-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ docker compose down -v
 Container gateway2  Stopping
 Container cli-kcat  Stopping
 Container mirror-maker  Stopping
 Container gateway1  Stopping
 Container schema-registry  Stopping
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container gateway2  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container mirror-maker  Stopped
 Container mirror-maker  Removing
 Container mirror-maker  Removed
 Container kafka1  Stopping
 Container kafka2  Stopping
 Container failover-kafka1  Stopping
 Container failover-kafka2  Stopping
 Container failover-kafka3  Stopping
 Container kafka3  Stopping
 Container cli-kcat  Stopped
 Container cli-kcat  Removing
 Container cli-kcat  Removed
 Container failover-kafka2  Stopped
 Container failover-kafka2  Removing
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka1  Stopped
 Container kafka1  Removing
 Container failover-kafka1  Stopped
 Container failover-kafka1  Removing
 Container kafka2  Stopped
 Container kafka2  Removing
 Container failover-kafka3  Stopped
 Container failover-kafka3  Removing
 Container kafka1  Removed
 Container failover-kafka1  Removed
 Container kafka3  Removed
 Container failover-kafka3  Removed
 Container failover-kafka2  Removed
 Container kafka2  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network cluster-switching_default  Removing
 Network cluster-switching_default  Removed

```

</details>

# Conclusion

you've seen something deeply interesting

