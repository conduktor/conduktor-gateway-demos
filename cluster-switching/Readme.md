# What is cluster switching?

Conduktor Gateway's cluster switching allows hot-switch the backend Kafka cluster without having to change your client configuration, or restart Gateway.

This features enables you to build a seamless disaster recovery strategy for your Kafka cluster, when Gateway is deployed in combination with a replication solution (like MirrorMaker, Confluent replicator, Cluster Linking, etc.).

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/kEZBR7FyZyG1XopdNd6t3RGUE.svg)](https://asciinema.org/a/kEZBR7FyZyG1XopdNd6t3RGUE)

## Limitations to consider when designing a disaster recovery strategy

* Cluster switching does not replicate data between clusters. You need to use a replication solution like MirrorMaker to replicate data between clusters
* Because of their asynchronous nature, such replication solutions may lead to data loss in case of a disaster
* Cluster switching is a manual process - automatic failover is not supported, yet
* Concentrated topics offsets: Gateway stores client offsets of concentrated topics in a regular Kafka topic. When replicating this topic, there will be no adjustments of potential offsets shifts between the source and failover cluster
* When switching, Kafka consumers will perform a group rebalance. They will not be able to commit their offset before the rebalance. This may lead to a some messages being consumed twice

## Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* failover-kafka1
* failover-kafka2
* failover-kafka3
* gateway1
* gateway2
* kafka-client
* kafka1
* kafka2
* kafka3
* mirror-maker
* schema-registry
* zookeeper

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
    - 19092:19092
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801
      KAFKA_LISTENERS: INTERNAL://:9092,EXTERNAL_SAME_HOST://:19092
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka1:9092,EXTERNAL_SAME_HOST://localhost:19092
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
    - 19093:19093
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801
      KAFKA_LISTENERS: INTERNAL://:9093,EXTERNAL_SAME_HOST://:19093
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka2:9093,EXTERNAL_SAME_HOST://localhost:19093
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
    - 19094:19094
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801
      KAFKA_LISTENERS: INTERNAL://:9094,EXTERNAL_SAME_HOST://:19094
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka3:9094,EXTERNAL_SAME_HOST://localhost:19094
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
    image: conduktor/conduktor-gateway:3.0.0
    hostname: gateway1
    container_name: gateway1
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_MODE: VCLUSTER
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
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
    image: conduktor/conduktor-gateway:3.0.0
    hostname: gateway2
    container_name: gateway2
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_MODE: VCLUSTER
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_START_PORT: 7969
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
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
  kafka-client:
    image: confluentinc/cp-kafka:latest
    hostname: kafka-client
    container_name: kafka-client
    command: sleep infinity
    volumes:
    - type: bind
      source: .
      target: /clientConfig
      read_only: true
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
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:29092,INTERNAL://:9092
      KAFKA_ADVERTISED_LISTENERS: EXTERNAL_SAME_HOST://localhost:29092,INTERNAL://failover-kafka1:9092
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
    - 29092:29092
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
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:29093,INTERNAL://:9093
      KAFKA_ADVERTISED_LISTENERS: EXTERNAL_SAME_HOST://localhost:29093,INTERNAL://failover-kafka2:9093
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
    - 29093:29093
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
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:29094,INTERNAL://:9094
      KAFKA_ADVERTISED_LISTENERS: EXTERNAL_SAME_HOST://localhost:29094,INTERNAL://failover-kafka3:9094
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
    - 29094:29094
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

## Review the Gateway configuration

Review the Gateway configuration

```sh
cat clusters.yaml
```

<details open>
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

## Review the Mirror-Maker configuration

Review the Mirror-Maker configuration

```sh
cat mm2.properties
```

<details>
<summary>File content</summary>

```properties
# specify any number of cluster aliases
clusters = main, failover

# connection information for each cluster
main.bootstrap.servers = kafka1:9092,kafka2:9093,kafka3:9094
failover.bootstrap.servers = failover-kafka1:9092,failover-kafka2:9093,failover-kafka3:9094

# enable and configure individual replication flows
main->failover.enabled = true
# Do not rename topics
replication.policy.class=org.apache.kafka.connect.mirror.IdentityReplicationPolicy

# regex which defines which topics gets replicated.
main->failover.topics = .*
refresh.topics.interval.seconds=10
main.consumer.auto.offset.reset=earliest

# regex which defines which consumer groups gets replicated.
main->failover.groups = .*
sync.group.offsets.enabled=true
refresh.groups.interval.seconds=10

# Setting replication factor of newly created remote topics
replication.factor=1

############################# Internal Topic Settings  #############################
# The replication factor for mm2 internal topics "heartbeats", "B.checkpoints.internal" and "mm2-offset-syncs.B.internal"
# For anything other than development testing, a value greater than 1 is recommended to ensure availability such as 3.
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

## Starting the docker environment

Start all your docker processes, wait for them to be up and ready, then run in background

* `--wait`: Wait for services to be `running|healthy`. Implies detached mode.
* `--detach`: Detached mode: Run containers in the background

<details open>
<summary>Command</summary>



```sh
docker compose up --detach --wait
```



</details>
<details>
<summary>Output</summary>

```
 Network cluster-switching_default  Creating
 Network cluster-switching_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container zookeeper  Created
 Container failover-kafka1  Creating
 Container kafka2  Creating
 Container failover-kafka2  Creating
 Container kafka1  Creating
 Container failover-kafka3  Creating
 Container kafka3  Creating
 Container kafka-client  Created
 Container kafka1  Created
 Container kafka2  Created
 Container failover-kafka3  Created
 Container kafka3  Created
 Container failover-kafka2  Created
 Container schema-registry  Creating
 Container gateway1  Creating
 Container gateway2  Creating
 Container failover-kafka1  Created
 Container mirror-maker  Creating
 Container gateway1  Created
 Container gateway2  Created
 Container schema-registry  Created
 Container mirror-maker  Created
 Container zookeeper  Starting
 Container kafka-client  Starting
 Container kafka-client  Started
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container failover-kafka2  Starting
 Container zookeeper  Healthy
 Container failover-kafka3  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container failover-kafka1  Starting
 Container kafka1  Started
 Container kafka2  Started
 Container failover-kafka2  Started
 Container failover-kafka1  Started
 Container kafka3  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container failover-kafka3  Started
 Container kafka3  Waiting
 Container failover-kafka1  Waiting
 Container failover-kafka2  Waiting
 Container failover-kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container gateway2  Starting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container failover-kafka1  Healthy
 Container kafka1  Healthy
 Container failover-kafka3  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container failover-kafka2  Healthy
 Container mirror-maker  Starting
 Container gateway1  Started
 Container mirror-maker  Started
 Container schema-registry  Started
 Container gateway2  Started
 Container failover-kafka3  Waiting
 Container kafka2  Waiting
 Container failover-kafka1  Waiting
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container gateway2  Waiting
 Container kafka1  Waiting
 Container schema-registry  Waiting
 Container failover-kafka2  Waiting
 Container kafka3  Waiting
 Container mirror-maker  Waiting
 Container gateway1  Waiting
 Container kafka-client  Healthy
 Container failover-kafka2  Healthy
 Container zookeeper  Healthy
 Container failover-kafka1  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container failover-kafka3  Healthy
 Container mirror-maker  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/fvoBiw8NVNqaI4oh8EzZb6AvF.svg)](https://asciinema.org/a/fvoBiw8NVNqaI4oh8EzZb6AvF)

</details>

## Creating virtual cluster teamA

Creating virtual cluster `teamA` on gateway `gateway1` and reviewing the configuration file to access it

<details>
<summary>Command</summary>



```sh
# Generate virtual cluster teamA with service account sa
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

# Create access file
echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > teamA-sa.properties

# Review file
cat teamA-sa.properties
```



</details>
<details>
<summary>Output</summary>

```

bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ3MTA2M30.RVlGt-y6NbeqGXs9I5rBXWZsSQuf4FfXBpVlEUG9YGI';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/VvG7y0NDB7FWBkaP3blwR7Ljf.svg)](https://asciinema.org/a/VvG7y0NDB7FWBkaP3blwR7Ljf)

</details>

## Creating topic users on teamA

Creating on `teamA`:

* Topic `users` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic users
```



</details>
<details>
<summary>Output</summary>

```
Created topic users.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Gx8jQh7dscU6SLinxphjmJ0lR.svg)](https://asciinema.org/a/Gx8jQh7dscU6SLinxphjmJ0lR)

</details>

## Send tom and laura into topic users

Producing 2 messages in `users` in cluster `teamA`

<details>
<summary>Command</summary>



Sending 2 events
```json
{
  "name" : "tom",
  "username" : "tom@conduktor.io",
  "password" : "motorhead",
  "visa" : "#abc123",
  "address" : "Chancery lane, London"
}
{
  "name" : "laura",
  "username" : "laura@conduktor.io",
  "password" : "kitesurf",
  "visa" : "#888999XZ",
  "address" : "Dubai, UAE"
}
```
with


```sh
echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users

echo '{"name":"laura","username":"laura@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/UhSzs9SnyFTvU5tvMsse9b8oV.svg)](https://asciinema.org/a/UhSzs9SnyFTvU5tvMsse9b8oV)

</details>

## Listing topics in kafka1



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --list
```



</details>
<details>
<summary>Output</summary>

```
__consumer_offsets
_conduktor_private_acls
_conduktor_private_auditlogs
_conduktor_private_consumer_offsets
_conduktor_private_consumer_subscriptions
_conduktor_private_encryption_configs
_conduktor_private_interceptor_configs
_conduktor_private_license
_conduktor_private_topicmappings
_conduktor_private_usermappings
_schemas
mm2-configs.failover.internal
mm2-offset-syncs.failover.internal
mm2-offsets.failover.internal
mm2-status.failover.internal
teamAusers

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/INYXYyI9hzuYFi0FigTPRuRgR.svg)](https://asciinema.org/a/INYXYyI9hzuYFi0FigTPRuRgR)

</details>

## Wait for mirror maker to do its job on gateway internal topic

Wait for mirror maker to do its job on gateway internal topic in cluster `failover-kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic _topicMappings \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 15000 | jq
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 00:37:51,382] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 2 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:51,504] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 9 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:51,702] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 11 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:52,124] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 12 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:53,071] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 13 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:54,077] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 14 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:55,048] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 16 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:56,053] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 17 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:56,970] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 18 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:57,939] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 20 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:58,945] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 21 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:37:59,962] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 22 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:38:00,968] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 24 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:38:01,887] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 25 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:38:02,898] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 26 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:38:03,847] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 28 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:38:04,772] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 29 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:38:05,705] WARN [Consumer clientId=console-consumer, groupId=console-consumer-2033] Error while fetching metadata with correlation id 30 : {_topicMappings=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)
[2024-04-10 00:38:06,208] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 0 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/VeM500sI6qqA3Zv7V22OSHKLQ.svg)](https://asciinema.org/a/VeM500sI6qqA3Zv7V22OSHKLQ)

</details>

## Wait for mirror maker to do its job on users topics

Wait for mirror maker to do its job on users topics in cluster `failover-kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 15000 | jq
```



</details>
<details>
<summary>Output</summary>

```json
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
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/oNQcqbNlIpbGkmwH6uM7USHeD.svg)](https://asciinema.org/a/oNQcqbNlIpbGkmwH6uM7USHeD)

</details>

## Assert mirror maker did its job



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --list
```



</details>
<details>
<summary>Output</summary>

```
__consumer_offsets
_conduktor_private_acls
_conduktor_private_auditlogs
_conduktor_private_consumer_offsets
_conduktor_private_consumer_subscriptions
_conduktor_private_encryption_configs
_conduktor_private_interceptor_configs
_conduktor_private_license
_conduktor_private_topicmappings
_conduktor_private_usermappings
_schemas
heartbeats
main.checkpoints.internal
main.heartbeats
mm2-configs.main.internal
mm2-offsets.main.internal
mm2-status.main.internal
teamAusers

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/pqOrb0TvpKSg5QXL7dVKnGLJf.svg)](https://asciinema.org/a/pqOrb0TvpKSg5QXL7dVKnGLJf)

</details>

## Failing over from main to failover

Failing over from `main` to `failover` on gateway `gateway1`

<details open>
<summary>Command</summary>



```sh
curl \
  --request POST 'http://localhost:8888/admin/pclusters/v1/pcluster/main/switch?to=failover' \
  --user 'admin:conduktor' \
  --silent | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "message": "Cluster switched"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/6jhEy9D8SNB40QMPyvDvFWJPH.svg)](https://asciinema.org/a/6jhEy9D8SNB40QMPyvDvFWJPH)

</details>

        From now on `gateway1` the cluster with id `main` is pointing to the `failover cluster.

## Failing over from main to failover

Failing over from `main` to `failover` on gateway `gateway2`

<details open>
<summary>Command</summary>



```sh
curl \
  --request POST 'http://localhost:8889/admin/pclusters/v1/pcluster/main/switch?to=failover' \
  --user 'admin:conduktor' \
  --silent | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "message": "Cluster switched"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/89JuPWLokJkm23FNDTKXaiLz5.svg)](https://asciinema.org/a/89JuPWLokJkm23FNDTKXaiLz5)

</details>

        From now on `gateway2` the cluster with id `main` is pointing to the `failover cluster.

## Produce alice into users, it should hit only failover-kafka

Producing 1 message in `users` in cluster `teamA`

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "name" : "alice",
  "username" : "alice@conduktor.io",
  "password" : "youpi",
  "visa" : "#812SSS",
  "address" : "Les ifs"
}
```
with


```sh
echo '{"name":"alice","username":"alice@conduktor.io","password":"youpi","visa":"#812SSS","address":"Les ifs"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users
```



</details>
<details>
<summary>Output</summary>

```
[2024-04-10 00:38:19,943] WARN [Producer clientId=console-producer] Bootstrap broker localhost:6969 (id: -1 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/MUy79cjx4mKMtcqh2pPWcMgjE.svg)](https://asciinema.org/a/MUy79cjx4mKMtcqh2pPWcMgjE)

</details>

## Verify we can read laura (via mirror maker), tom (via mirror maker) and alice (via cluster switching)

Verify we can read laura (via mirror maker), tom (via mirror maker) and alice (via cluster switching) in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 10000 | jq
```


returns 1 event
```json
{
  "name" : "alice",
  "username" : "alice@conduktor.io",
  "password" : "youpi",
  "visa" : "#812SSS",
  "address" : "Les ifs"
}
```



</details>
<details>
<summary>Output</summary>

```json
Processed a total of 3 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
}
{
  "name": "laura",
  "username": "laura@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ",
  "address": "Dubai, UAE"
}
{
  "name": "alice",
  "username": "alice@conduktor.io",
  "password": "youpi",
  "visa": "#812SSS",
  "address": "Les ifs"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/HE6nke2YN9TZslo1YJzSNbGFu.svg)](https://asciinema.org/a/HE6nke2YN9TZslo1YJzSNbGFu)

</details>

## Verify alice is not in main kafka

Verify alice is not in main kafka in cluster `kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic teamAusers \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 2 events
```json
{
  "name" : "tom",
  "username" : "tom@conduktor.io",
  "password" : "motorhead",
  "visa" : "#abc123",
  "address" : "Chancery lane, London"
}
{
  "name" : "laura",
  "username" : "laura@conduktor.io",
  "password" : "kitesurf",
  "visa" : "#888999XZ",
  "address" : "Dubai, UAE"
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 00:38:34,473] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
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
  "name": "laura",
  "username": "laura@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ",
  "address": "Dubai, UAE"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/xywbrinHagi2dFIJp2I5C7r4g.svg)](https://asciinema.org/a/xywbrinHagi2dFIJp2I5C7r4g)

</details>

## Verify alice is in failover

Verify alice is in failover in cluster `failover-kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 15000 | jq
```


returns 1 event
```json
{
  "name" : "alice",
  "username" : "alice@conduktor.io",
  "password" : "youpi",
  "visa" : "#812SSS",
  "address" : "Les ifs"
}
```



</details>
<details>
<summary>Output</summary>

```json
Processed a total of 3 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
}
{
  "name": "laura",
  "username": "laura@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ",
  "address": "Dubai, UAE"
}
{
  "name": "alice",
  "username": "alice@conduktor.io",
  "password": "youpi",
  "visa": "#812SSS",
  "address": "Les ifs"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Sj59PB9sxRYz3J3r8oBxoylSA.svg)](https://asciinema.org/a/Sj59PB9sxRYz3J3r8oBxoylSA)

</details>

## Tearing down the docker environment

Remove all your docker processes and associated volumes

* `--volumes`: Remove named volumes declared in the "volumes" section of the Compose file and anonymous volumes attached to containers.

<details open>
<summary>Command</summary>



```sh
docker compose down --volumes
```



</details>
<details>
<summary>Output</summary>

```
 Container mirror-maker  Stopping
 Container kafka-client  Stopping
 Container gateway1  Stopping
 Container gateway2  Stopping
 Container schema-registry  Stopping
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway2  Removed
 Container gateway1  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container mirror-maker  Stopped
 Container mirror-maker  Removing
 Container mirror-maker  Removed
 Container kafka3  Stopping
 Container failover-kafka3  Stopping
 Container kafka2  Stopping
 Container failover-kafka2  Stopping
 Container failover-kafka1  Stopping
 Container kafka1  Stopping
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container failover-kafka2  Stopped
 Container failover-kafka2  Removing
 Container failover-kafka2  Removed
 Container kafka-client  Stopped
 Container kafka-client  Removing
 Container kafka-client  Removed
 Container failover-kafka3  Stopped
 Container failover-kafka3  Removing
 Container failover-kafka3  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container failover-kafka1  Stopped
 Container failover-kafka1  Removing
 Container failover-kafka1  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network cluster-switching_default  Removing
 Network cluster-switching_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/WyhpFUu12p98XVK3NQfMGKw6F.svg)](https://asciinema.org/a/WyhpFUu12p98XVK3NQfMGKw6F)

</details>

# Conclusion

Cluster switching help your seamlessly move from one cluster to another!

