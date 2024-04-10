# Infinite Partitions with Topic Concentration

Conduktor Gateway's topic concentration feature allows you to store multiple topics's data on a single underlying Kafka topic. 

To clients, it appears that there are multiple topics and these can be read from as normal but in the underlying Kafka cluster there is a lot less resource required.

In this demo we are going to create a concentrated topic for powering several virtual topics. 

Create the virtual topics, produce and consume data to them, and explore how this works.

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/0CC66lIpqAh3NvDgOB819UsqM.svg)](https://asciinema.org/a/0CC66lIpqAh3NvDgOB819UsqM)

## Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
* kafka-client
* kafka1
* kafka2
* kafka3
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
networks:
  demo: null
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
 Network topic-concentration_default  Creating
 Network topic-concentration_default  Created
 Container kafka-client  Creating
 Container zookeeper  Creating
 Container kafka-client  Created
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka1  Creating
 Container kafka2  Creating
 Container kafka1  Created
 Container kafka3  Created
 Container kafka2  Created
 Container gateway1  Creating
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Created
 Container schema-registry  Created
 Container gateway2  Created
 Container zookeeper  Starting
 Container kafka-client  Starting
 Container kafka-client  Started
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container kafka1  Started
 Container kafka2  Started
 Container kafka3  Started
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container schema-registry  Starting
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container gateway2  Starting
 Container gateway2  Started
 Container schema-registry  Started
 Container gateway1  Started
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container kafka-client  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container zookeeper  Healthy
 Container gateway1  Healthy
 Container schema-registry  Healthy
 Container gateway2  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/jEriJWdRkXIswEbN89TgLP44p.svg)](https://asciinema.org/a/jEriJWdRkXIswEbN89TgLP44p)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ4NjcxN30.foVOiaZnHOTc-C0p5TCYohdUSJyrOAPACu_lj1Twr6Q';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/3byKOhCe19Fp5emKdLzp4OMlJ.svg)](https://asciinema.org/a/3byKOhCe19Fp5emKdLzp4OMlJ)

</details>

## Create the topic that will hold concentrated topics

Creating on `kafka1`:

* Topic `hold_many_concentrated_topics` with partitions:5 and replication-factor:1
* Topic `hold_many_concentrated_topics_compacted` with partitions:5 and replication-factor:1
* Topic `hold_many_concentrated_topics_compacted_deleted` with partitions:5 and replication-factor:1

<details>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 5 \
    --create --if-not-exists \
    --topic hold_many_concentrated_topics
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 5 \
    --config cleanup.policy=compact \
    --create --if-not-exists \
    --topic hold_many_concentrated_topics_compacted
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 5 \
    --config cleanup.policy=compact,delete \
    --create --if-not-exists \
    --topic hold_many_concentrated_topics_compacted_deleted
```



</details>
<details>
<summary>Output</summary>

```
WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
Created topic hold_many_concentrated_topics.
WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
Created topic hold_many_concentrated_topics_compacted.
WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
Created topic hold_many_concentrated_topics_compacted_deleted.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Q7cKgoEffmxsx7krBlUc7fgHr.svg)](https://asciinema.org/a/Q7cKgoEffmxsx7krBlUc7fgHr)

</details>

## Creating concentration rule for pattern concentrated-.* to hold_many_concentrated_topics



<details open>
<summary>Command</summary>



```sh
cat step-07-concentration-rule.json | jq

curl \
    --request POST 'http://localhost:8888/admin/vclusters/v1/vcluster/teamA/concentration-rules' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data "@step-07-concentration-rule.json" | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "clusterId": "main",
  "physicalTopicName": "hold_many_concentrated_topics",
  "physicalTopicCompactedName": "hold_many_concentrated_topics_compacted",
  "physicalTopicCompactedDeletedName": "hold_many_concentrated_topics_compacted_deleted",
  "pattern": "concentrated-.*"
}
{
  "clusterId": "main",
  "pattern": "concentrated-.*",
  "physicalTopicName": "hold_many_concentrated_topics"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/657xp95whP9eJQ2QqxYprEhQg.svg)](https://asciinema.org/a/657xp95whP9eJQ2QqxYprEhQg)

</details>

## Create concentrated topics

Creating on `teamA`:

* Topic `concentrated-normal` with partitions:1 and replication-factor:1
* Topic `concentrated-deleted` with partitions:1 and replication-factor:1
* Topic `concentrated-compact` with partitions:1 and replication-factor:1
* Topic `concentrated-delete-compact` with partitions:1 and replication-factor:1
* Topic `concentrated-compact-delete` with partitions:1 and replication-factor:1

<details>
<summary>Command</summary>



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
    --topic concentrated-deleted
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
```



</details>
<details>
<summary>Output</summary>

```
Created topic concentrated-normal.
Created topic concentrated-deleted.
Created topic concentrated-compact.
Created topic concentrated-delete-compact.
Created topic concentrated-compact-delete.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/bjp8BR3Zn2D5e4UDOVHrFRNuU.svg)](https://asciinema.org/a/bjp8BR3Zn2D5e4UDOVHrFRNuU)

</details>

## Assert the topics have been created



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
```



</details>
<details>
<summary>Output</summary>

```
concentrated-compact
concentrated-compact-delete
concentrated-delete-compact
concentrated-deleted
concentrated-normal

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/xHfQuC6z1m4p9l4WQHFj6n1MP.svg)](https://asciinema.org/a/xHfQuC6z1m4p9l4WQHFj6n1MP)

</details>

## Assert the topics have not been created in the underlying kafka cluster

If we list topics from the backend cluster, not from Gateway perspective, we do not see the concentrated topics.

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
_conduktor_gateway_acls
_conduktor_gateway_auditlogs
_conduktor_gateway_consumer_offsets
_conduktor_gateway_consumer_subscriptions
_conduktor_gateway_encryption_configs
_conduktor_gateway_interceptor_configs
_conduktor_gateway_license
_conduktor_gateway_topicmappings
_conduktor_gateway_usermappings
_schemas
hold_many_concentrated_topics
hold_many_concentrated_topics_compacted
hold_many_concentrated_topics_compacted_deleted

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/kbL1inwFTct30lXadsohcpOM7.svg)](https://asciinema.org/a/kbL1inwFTct30lXadsohcpOM7)

</details>

## Let's continue created virtual topics, but now with many partitions

Creating on `teamA`:

* Topic `concentrated-topic-with-10-partitions` with partitions:10 and replication-factor:1
* Topic `concentrated-topic-with-100-partitions` with partitions:100 and replication-factor:1

<details>
<summary>Command</summary>



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



</details>
<details>
<summary>Output</summary>

```
Created topic concentrated-topic-with-10-partitions.
Created topic concentrated-topic-with-100-partitions.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/vXLDdXpLnoSN8tpaR2Zc334Pz.svg)](https://asciinema.org/a/vXLDdXpLnoSN8tpaR2Zc334Pz)

</details>

## Assert they exist in teamA cluster



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
```



</details>
<details>
<summary>Output</summary>

```
concentrated-compact
concentrated-compact-delete
concentrated-delete-compact
concentrated-deleted
concentrated-normal
concentrated-topic-with-10-partitions
concentrated-topic-with-100-partitions

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/dOXlzVly8GdlEsFMAMJHIvtDe.svg)](https://asciinema.org/a/dOXlzVly8GdlEsFMAMJHIvtDe)

</details>

## Producing 1 message in concentrated-topic-with-10-partitions

Producing 1 message in `concentrated-topic-with-10-partitions` in cluster `teamA`

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "type" : "Sports",
  "price" : 75,
  "color" : "blue"
}
```
with


```sh
echo '{"type": "Sports", "price": 75, "color": "blue"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic concentrated-topic-with-10-partitions
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/mxHxya8Rhe7kCiMFH4tU5pdEB.svg)](https://asciinema.org/a/mxHxya8Rhe7kCiMFH4tU5pdEB)

</details>

## Consuming from concentrated-topic-with-10-partitions

Consuming from concentrated-topic-with-10-partitions in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic concentrated-topic-with-10-partitions \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 1 event
```json
{
  "type" : "Sports",
  "price" : 75,
  "color" : "blue"
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 04:59:07,537] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "type": "Sports",
  "price": 75,
  "color": "blue"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/4VVrp0PKpR2LBDO5FNNf3J4KB.svg)](https://asciinema.org/a/4VVrp0PKpR2LBDO5FNNf3J4KB)

</details>

## Producing 1 message in concentrated-topic-with-100-partitions

Producing 1 message in `concentrated-topic-with-100-partitions` in cluster `teamA`

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "msg" : "hello world"
}
```
with


```sh
echo '{"msg":"hello world"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic concentrated-topic-with-100-partitions
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/7wvDHUJMBfCrJJmqL8hxHcvUZ.svg)](https://asciinema.org/a/7wvDHUJMBfCrJJmqL8hxHcvUZ)

</details>

## Consuming from concentrated-topic-with-100-partitions

Consuming from concentrated-topic-with-100-partitions in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic concentrated-topic-with-100-partitions \
    --from-beginning \
    --timeout-ms 10000 | jq
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 04:59:20,854] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "msg": "hello world"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/LaSqqDUhwJrccZ8jL8KFT7I8q.svg)](https://asciinema.org/a/LaSqqDUhwJrccZ8jL8KFT7I8q)

</details>

## Consuming from concentrated-topic-with-100-partitions

Consuming from concentrated-topic-with-100-partitions in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic concentrated-topic-with-100-partitions \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 1 event
```json
{
  "msg" : "hello world"
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 04:59:32,817] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "msg": "hello world"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/FOJ1ECyyzLhKxecC5PINdaEwa.svg)](https://asciinema.org/a/FOJ1ECyyzLhKxecC5PINdaEwa)

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
 Container schema-registry  Stopping
 Container kafka-client  Stopping
 Container gateway2  Stopping
 Container gateway1  Stopping
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka3  Stopping
 Container kafka1  Stopping
 Container kafka2  Stopping
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka-client  Stopped
 Container kafka-client  Removing
 Container kafka-client  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network topic-concentration_default  Removing
 Network topic-concentration_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/ebyaTUHz7r5ORYjMDQLIQFMh0.svg)](https://asciinema.org/a/ebyaTUHz7r5ORYjMDQLIQFMh0)

</details>

# Conclusion

Infinite partitions with topic concentration is really a game changer!

