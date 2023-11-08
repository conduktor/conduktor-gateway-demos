# What is cluster switching?

Conduktor Gateway's cluster switching allows hot-switch the backend Kafka cluster without having to change your client configuration, or restart Gateway.

This features enables you to build a seamless disaster recovery strategy for your Kafka cluster, when Gateway is deployed in combination with a replication solution (like MirrorMaker, Confluent replicator, Cluster Linking, etc.).

## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/X74k7J1R3lnp9WABb3AixywwH.svg)](https://asciinema.org/a/X74k7J1R3lnp9WABb3AixywwH)

## Limitations to consider when designing a disaster recovery strategy

* Cluster switching does not replicate data between clusters. You need to use a replication solution like MirrorMaker to replicate data between clusters
* Because of their asynchronous nature, such replication solutions may lead to data loss in case of a disaster
* Cluster switching is a manual process - automatic failover is not supported, yet
* Concentrated topics offsets: Gateway stores client offsets of concentrated topics in a regular Kafka topic. When replicating this topic, there will be no adjustments of potential offsets shifts between the source and failover cluster
* When switching, Kafka consumers will perform a group rebalance. They will not be able to commit their offset before the rebalance. This may lead to a some messages being consumed twice

### Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* failover-kafka1
* failover-kafka2
* failover-kafka3
* gateway1
* gateway2
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
    image: conduktor/conduktor-gateway:2.5.0
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
    image: conduktor/conduktor-gateway:2.5.0
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

 <details>
  <summary>docker compose ps</summary>

```
NAME              IMAGE                                    COMMAND                  SERVICE           CREATED          STATUS                    PORTS
failover-kafka1   confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   failover-kafka1   38 seconds ago   Up 30 seconds (healthy)   9092/tcp, 0.0.0.0:29092->29092/tcp
failover-kafka2   confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   failover-kafka2   38 seconds ago   Up 30 seconds (healthy)   9092/tcp, 0.0.0.0:29093->29093/tcp
failover-kafka3   confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   failover-kafka3   38 seconds ago   Up 31 seconds (healthy)   9092/tcp, 0.0.0.0:29094->29094/tcp
gateway1          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway1          37 seconds ago   Up 25 seconds (healthy)   0.0.0.0:6969-6971->6969-6971/tcp, 0.0.0.0:8888->8888/tcp
gateway2          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway2          37 seconds ago   Up 25 seconds (healthy)   0.0.0.0:7969-7971->7969-7971/tcp, 0.0.0.0:8889->8888/tcp
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            38 seconds ago   Up 31 seconds (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            38 seconds ago   Up 31 seconds (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
kafka3            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka3            38 seconds ago   Up 31 seconds (healthy)   9092/tcp, 0.0.0.0:19094->19094/tcp
mirror-maker      confluentinc/cp-kafka:latest             "connect-mirror-make…"   mirror-maker      37 seconds ago   Up 20 seconds (healthy)   9092/tcp
schema-registry   confluentinc/cp-schema-registry:latest   "/etc/confluent/dock…"   schema-registry   37 seconds ago   Up 25 seconds (healthy)   0.0.0.0:8081->8081/tcp
zookeeper         confluentinc/cp-zookeeper:latest         "/etc/confluent/dock…"   zookeeper         38 seconds ago   Up 37 seconds (healthy)   2181/tcp, 2888/tcp, 3888/tcp

```

</details>

### Review the Gateway configuration

Review the Gateway configuration

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

```sh
docker compose up --detach --wait
```

<details>
  <summary>Realtime command output</summary>

  ![Starting the docker environment](images/step-07-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose up --detach --wait
 Network cluster-switching_default  Creating
 Network cluster-switching_default  Created
 Container zookeeper  Creating
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka1  Creating
 Container failover-kafka3  Creating
 Container failover-kafka2  Creating
 Container failover-kafka1  Creating
 Container kafka2  Creating
 Container kafka1  Created
 Container kafka3  Created
 Container failover-kafka1  Created
 Container failover-kafka3  Created
 Container failover-kafka2  Created
 Container kafka2  Created
 Container mirror-maker  Creating
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Creating
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway1  Created
 Container gateway2  Created
 Container schema-registry  Created
 Container mirror-maker  Created
 Container zookeeper  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container failover-kafka2  Starting
 Container zookeeper  Healthy
 Container failover-kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container failover-kafka3  Starting
 Container failover-kafka1  Started
 Container failover-kafka3  Started
 Container kafka2  Started
 Container kafka1  Started
 Container failover-kafka2  Started
 Container kafka3  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container failover-kafka1  Waiting
 Container failover-kafka2  Waiting
 Container failover-kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka2  Healthy
 Container failover-kafka1  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container failover-kafka2  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container gateway2  Starting
 Container failover-kafka3  Healthy
 Container mirror-maker  Starting
 Container schema-registry  Started
 Container mirror-maker  Started
 Container gateway2  Started
 Container gateway1  Started
 Container failover-kafka3  Waiting
 Container failover-kafka2  Waiting
 Container kafka1  Waiting
 Container schema-registry  Waiting
 Container kafka3  Waiting
 Container mirror-maker  Waiting
 Container kafka2  Waiting
 Container zookeeper  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container failover-kafka1  Waiting
 Container zookeeper  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container failover-kafka3  Healthy
 Container failover-kafka2  Healthy
 Container failover-kafka1  Healthy
 Container kafka1  Healthy
 Container mirror-maker  Healthy
 Container schema-registry  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy

```

</details>
      


## Creating virtual cluster `teamA`

Creating virtual cluster `teamA` on gateway `gateway1`

```sh
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
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

  ![Creating virtual cluster `teamA`](images/step-08-CREATE_VIRTUAL_CLUSTER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")
curl     --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa"     --header 'Content-Type: application/json'     --user 'admin:conduktor'     --silent     --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token"

echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > teamA-sa.properties

```

</details>
      


### Review the kafka properties to connect to `teamA`

Review the kafka properties to connect to `teamA`

```sh
cat teamA-sa.properties
```

<details on>
  <summary>File content</summary>

```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzcyMDE3OX0.NCW2vM8CYFw-GOt29zlGmlfvq4Zuow8KVoxgfcxRvYc';
bootstrap.servers=localhost:6969
```

</details>


## Creating topic `users` on `teamA`

Creating topic `users` on `teamA`
* Topic `users` with partitions:1 and replication-factor:1

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

  ![Creating topic `users` on `teamA`](images/step-10-CREATE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic users
Created topic users.

```

</details>
      


## Send `tom` and `florent` into topic `users`

Producing 2 messages in `users` in cluster `teamA`

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

  ![Send `tom` and `florent` into topic `users`](images/step-11-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

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

</details>
      


## Listing topics in `kafka1`



```sh
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `kafka1`](images/step-12-LIST_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --list
__consumer_offsets
_acls
_auditLogs
_consumerGroupSubscriptionBackingTopic
_encryptionConfig
_interceptorConfigs
_license
_offsetStore
_schemas
_topicMappings
_topicRegistry
_userMapping
heartbeats
mm2-configs.failover.internal
mm2-offset-syncs.failover.internal
mm2-offsets.failover.internal
mm2-status.failover.internal
teamAusers

```

</details>
      


## Wait for mirror maker to do its job on gateway internal topic

Wait for mirror maker to do its job on gateway internal topic in cluster `failover-kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic _topicMappings \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 15000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Wait for mirror maker to do its job on gateway internal topic](images/step-13-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic _topicMappings \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 15000 \
 | jq
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
      2024,
      1,
      22,
      17,
      24,
      8,
      672
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
      


## Wait for mirror maker to do its job on `users` topics

Wait for mirror maker to do its job on `users` topics in cluster `failover-kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 15000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Wait for mirror maker to do its job on `users` topics](images/step-14-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 15000 \
 | jq
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
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Assert mirror maker did its job](images/step-15-LIST_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --list
__consumer_offsets
_acls
_auditLogs
_consumerGroupSubscriptionBackingTopic
_encryptionConfig
_interceptorConfigs
_license
_offsetStore
_schemas
_topicMappings
_topicRegistry
_userMapping
heartbeats
main.checkpoints.internal
main.heartbeats
mm2-configs.main.internal
mm2-offsets.main.internal
mm2-status.main.internal
teamAusers

```

</details>
      


## Failing over from `main` to `failover`

Failing over from `main` to `failover` on gateway `gateway1`

```sh
curl \
  --request POST 'http://localhost:8888/admin/pclusters/v1/pcluster/main/switch?to=failover' \
  --user 'admin:conduktor' \
  --silent | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Failing over from `main` to `failover`](images/step-16-FAILOVER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

curl \
  --request POST 'http://localhost:8888/admin/pclusters/v1/pcluster/main/switch?to=failover' \
  --user 'admin:conduktor' \
  --silent | jq
{
  "message": "Cluster switched"
}

```

</details>
      


From now on `gateway1` the cluster with id `main` is pointing to the `failover cluster.

## Failing over from `main` to `failover`

Failing over from `main` to `failover` on gateway `gateway2`

```sh
curl \
  --request POST 'http://localhost:8889/admin/pclusters/v1/pcluster/main/switch?to=failover' \
  --user 'admin:conduktor' \
  --silent | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Failing over from `main` to `failover`](images/step-17-FAILOVER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

curl \
  --request POST 'http://localhost:8889/admin/pclusters/v1/pcluster/main/switch?to=failover' \
  --user 'admin:conduktor' \
  --silent | jq
{
  "message": "Cluster switched"
}

```

</details>
      


From now on `gateway2` the cluster with id `main` is pointing to the `failover cluster.

## Produce `thibault` into `users`, it should hit only `failover-kafka`

Producing 1 message in `users` in cluster `teamA`

```sh
echo '{"name":"thibaut","username":"thibaut@conduktor.io","password":"youpi","visa":"#812SSS","address":"Les ifs"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users
```

<details>
  <summary>Realtime command output</summary>

  ![Produce `thibault` into `users`, it should hit only `failover-kafka`](images/step-18-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"name":"thibaut","username":"thibaut@conduktor.io","password":"youpi","visa":"#812SSS","address":"Les ifs"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users

```

</details>
      


## Verify we can read `florent` (via mirror maker), `tom` (via mirror maker) and `thibault` (via cluster switching)

Verify we can read `florent` (via mirror maker), `tom` (via mirror maker) and `thibault` (via cluster switching) in cluster `teamA`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Verify we can read `florent` (via mirror maker), `tom` (via mirror maker) and `thibault` (via cluster switching)](images/step-19-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 10000 \
 | jq
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
      


## Verify `thibaut` is not in main kafka

Verify `thibaut` is not in main kafka in cluster `kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic teamAusers \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Verify `thibaut` is not in main kafka](images/step-20-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic teamAusers \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 18:24:46,365] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
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
      


## Verify `thibaut` is in failover

Verify `thibaut` is in failover in cluster `failover-kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 15000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Verify `thibaut` is in failover](images/step-21-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic teamAusers \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 15000 \
 | jq
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
      


## Tearing down the docker environment

Remove all your docker processes and associated volumes

* `--volumes`: Remove named volumes declared in the "volumes" section of the Compose file and anonymous volumes attached to containers.

```sh
docker compose down --volumes
```

<details>
  <summary>Realtime command output</summary>

  ![Tearing down the docker environment](images/step-22-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose down --volumes
 Container gateway2  Stopping
 Container mirror-maker  Stopping
 Container gateway1  Stopping
 Container schema-registry  Stopping
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container mirror-maker  Stopped
 Container mirror-maker  Removing
 Container mirror-maker  Removed
 Container kafka3  Stopping
 Container failover-kafka3  Stopping
 Container kafka1  Stopping
 Container failover-kafka2  Stopping
 Container kafka2  Stopping
 Container failover-kafka1  Stopping
 Container failover-kafka3  Stopped
 Container failover-kafka3  Removing
 Container failover-kafka3  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container failover-kafka1  Stopped
 Container failover-kafka1  Removing
 Container failover-kafka1  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container failover-kafka2  Stopped
 Container failover-kafka2  Removing
 Container kafka2  Removed
 Container failover-kafka2  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network cluster-switching_default  Removing
 Network cluster-switching_default  Removed

```

</details>
      


# Conclusion

Cluster switching help your seamlessly move from one cluster to another!

