# Multi-tenancy, virtual clusters



## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/GHPuT1isgi34Id9nAwgJaB5K9.svg)](https://asciinema.org/a/GHPuT1isgi34Id9nAwgJaB5K9)

### Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
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
    image: conduktor/conduktor-gateway:2.5.0
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
networks:
  demo: null
```

</details>

 <details>
  <summary>docker compose ps</summary>

```
NAME              IMAGE                                    COMMAND                  SERVICE           CREATED          STATUS                    PORTS
gateway1          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway1          27 seconds ago   Up 15 seconds (healthy)   0.0.0.0:6969-6971->6969-6971/tcp, 0.0.0.0:8888->8888/tcp
gateway2          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway2          27 seconds ago   Up 15 seconds (healthy)   0.0.0.0:7969-7971->7969-7971/tcp, 0.0.0.0:8889->8888/tcp
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            27 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            27 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
kafka3            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka3            27 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19094->19094/tcp
schema-registry   confluentinc/cp-schema-registry:latest   "/etc/confluent/dock…"   schema-registry   27 seconds ago   Up 15 seconds (healthy)   0.0.0.0:8081->8081/tcp
zookeeper         confluentinc/cp-zookeeper:latest         "/etc/confluent/dock…"   zookeeper         28 seconds ago   Up 27 seconds (healthy)   2181/tcp, 2888/tcp, 3888/tcp

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

  ![Starting the docker environment](images/step-04-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose up --detach --wait
 Network multi-tenancy_default  Creating
 Network multi-tenancy_default  Created
 Container zookeeper  Creating
 Container zookeeper  Created
 Container kafka1  Creating
 Container kafka2  Creating
 Container kafka3  Creating
 Container kafka3  Created
 Container kafka2  Created
 Container kafka1  Created
 Container schema-registry  Creating
 Container gateway1  Creating
 Container gateway2  Creating
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container zookeeper  Starting
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
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka1  Healthy
 Container gateway2  Starting
 Container schema-registry  Started
 Container gateway1  Started
 Container gateway2  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container zookeeper  Healthy
 Container schema-registry  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy

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

  ![Listing topics in `kafka1`](images/step-05-LIST_TOPICS.gif)

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

```

</details>
      


## Creating virtual cluster `london`

Creating virtual cluster `london` on gateway `gateway1`

```sh
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/london/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
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

  ![Creating virtual cluster `london`](images/step-06-CREATE_VIRTUAL_CLUSTER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/london/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")
curl     --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/london/username/sa"     --header 'Content-Type: application/json'     --user 'admin:conduktor'     --silent     --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token"

echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > london-sa.properties

```

</details>
      


## Creating virtual cluster `paris`

Creating virtual cluster `paris` on gateway `gateway1`

```sh
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/paris/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
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

  ![Creating virtual cluster `paris`](images/step-07-CREATE_VIRTUAL_CLUSTER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/paris/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")
curl     --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/paris/username/sa"     --header 'Content-Type: application/json'     --user 'admin:conduktor'     --silent     --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token"

echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > paris-sa.properties

```

</details>
      


## Creating topic `londonTopic` on `london`

Creating topic `londonTopic` on `london`
* Topic `londonTopic` with partitions:1 and replication-factor:1

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

  ![Creating topic `londonTopic` on `london`](images/step-08-CREATE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config london-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic londonTopic
Created topic londonTopic.

```

</details>
      


## Creating topic `parisTopic` on `paris`

Creating topic `parisTopic` on `paris`
* Topic `parisTopic` with partitions:1 and replication-factor:1

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

  ![Creating topic `parisTopic` on `paris`](images/step-09-CREATE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config paris-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic parisTopic
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

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config london-sa.properties \
    --list
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

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config paris-sa.properties \
    --list
parisTopic

```

</details>
      


## Producing 1 message in `londonTopic`

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

  ![Producing 1 message in `londonTopic`](images/step-12-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"message: "Hello from London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config london-sa.properties \
        --topic londonTopic

```

</details>
      


## Consuming from `londonTopic`

Consuming from `londonTopic` in cluster `london`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic londonTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `londonTopic`](images/step-13-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic londonTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
jq: parse error: Invalid numeric literal at line 1, column 18
[2024-01-23 00:07:23,671] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

```

</details>
      


## Producing 1 message in `parisTopic`

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

  ![Producing 1 message in `parisTopic`](images/step-14-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"message: "Bonjour depuis Paris"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config paris-sa.properties \
        --topic parisTopic

```

</details>
      


## Consuming from `parisTopic`

Consuming from `parisTopic` in cluster `paris`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config paris-sa.properties \
    --topic parisTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `parisTopic`](images/step-15-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config paris-sa.properties \
    --topic parisTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
jq: parse error: Invalid numeric literal at line 1, column 20
[2024-01-23 00:07:36,940] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

```

</details>
      


## Creating topic `existingLondonTopic` on `kafka1`

Creating topic `existingLondonTopic` on `kafka1`
* Topic `existingLondonTopic` with partitions:1 and replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic existingLondonTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `existingLondonTopic` on `kafka1`](images/step-16-CREATE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic existingLondonTopic
Created topic existingLondonTopic.

```

</details>
      


## Producing 1 message in `existingLondonTopic`

Producing 1 message in `existingLondonTopic` in cluster `kafka1`

```sh
echo '{"message: "Hello from London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
        --topic existingLondonTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Producing 1 message in `existingLondonTopic`](images/step-17-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"message: "Hello from London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
        --topic existingLondonTopic

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

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config london-sa.properties \
    --list
existingLondonTopic
londonTopic

```

</details>
      


## Creating topic `existingSharedTopic` on `kafka1`

Creating topic `existingSharedTopic` on `kafka1`
* Topic `existingSharedTopic` with partitions:1 and replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic existingSharedTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `existingSharedTopic` on `kafka1`](images/step-20-CREATE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic existingSharedTopic
Created topic existingSharedTopic.

```

</details>
      


## Producing 1 message in `existingSharedTopic`

Producing 1 message in `existingSharedTopic` in cluster `kafka1`

```sh
echo '{"message": "Existing shared message"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
        --topic existingSharedTopic
```

<details>
  <summary>Realtime command output</summary>

  ![Producing 1 message in `existingSharedTopic`](images/step-21-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"message": "Existing shared message"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
        --topic existingSharedTopic

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

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config london-sa.properties \
    --list
existingLondonTopic
existingSharedTopic
londonTopic

```

</details>
      


## Consuming from `existingLondonTopic`

Consuming from `existingLondonTopic` in cluster `london`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic existingLondonTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `existingLondonTopic`](images/step-24-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic existingLondonTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
jq: parse error: Invalid numeric literal at line 1, column 18
[2024-01-23 00:07:56,949] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

```

</details>
      


## Consuming from `existingSharedTopic`

Consuming from `existingSharedTopic` in cluster `london`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `existingSharedTopic`](images/step-25-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config london-sa.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-23 00:08:08,730] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
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

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config paris-sa.properties \
    --list
existingSharedTopic
parisTopic

```

</details>
      


## Consuming from `existingSharedTopic`

Consuming from `existingSharedTopic` in cluster `paris`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config paris-sa.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `existingSharedTopic`](images/step-28-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config paris-sa.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-23 00:08:22,012] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "message": "Existing shared message"
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

  ![Tearing down the docker environment](images/step-29-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose down --volumes
 Container gateway1  Stopping
 Container schema-registry  Stopping
 Container gateway2  Stopping
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka1  Stopping
 Container kafka3  Stopping
 Container kafka2  Stopping
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network multi-tenancy_default  Removing
 Network multi-tenancy_default  Removed

```

</details>
      


# Conclusion

Multi-tenancy/Virtual clusters is key to be in control of your kafka spend!

