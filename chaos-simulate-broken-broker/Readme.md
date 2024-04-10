# Simulate Broken Brokers

This interceptor injects intermittent errors in client connections to brokers that are consistent with broker side issues.

This demo will run you through some of these use cases step-by-step.

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/o1mNOmo1rF0ylY1WjKkZaXm6r.svg)](https://asciinema.org/a/o1mNOmo1rF0ylY1WjKkZaXm6r)

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
 Network chaos-simulate-broken-broker_default  Creating
 Network chaos-simulate-broken-broker_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container zookeeper  Created
 Container kafka-client  Created
 Container kafka2  Creating
 Container kafka3  Creating
 Container kafka1  Creating
 Container kafka1  Created
 Container kafka3  Created
 Container kafka2  Created
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Creating
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container kafka-client  Starting
 Container zookeeper  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container kafka-client  Started
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container kafka3  Started
 Container kafka1  Started
 Container kafka2  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container gateway2  Starting
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container schema-registry  Starting
 Container schema-registry  Started
 Container gateway2  Started
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
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container zookeeper  Healthy
 Container kafka2  Healthy
 Container gateway2  Healthy
 Container schema-registry  Healthy
 Container gateway1  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/ABbSpgSU4kURCmHWfvyStSRz5.svg)](https://asciinema.org/a/ABbSpgSU4kURCmHWfvyStSRz5)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ2OTE4NX0.MzNJ6obH4kQ-q-fcqoCi2IvqmZ6KOzkP7fD75oJ32mc';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/8K7nVRbP5rDJ42eenAdOvk5qu.svg)](https://asciinema.org/a/8K7nVRbP5rDJ42eenAdOvk5qu)

</details>

## Creating topic my-topic on teamA

Creating on `teamA`:

* Topic `my-topic` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic my-topic
```



</details>
<details>
<summary>Output</summary>

```
Created topic my-topic.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/1VWEagSr8l3r9osMMrl1zDMFs.svg)](https://asciinema.org/a/1VWEagSr8l3r9osMMrl1zDMFs)

</details>

## Adding interceptor simulate-broken-brokers

Let's create the interceptor against the virtual cluster teamA, instructing Conduktor Gateway to inject failures for some Produce requests that are consistent with broker side issues.

Creating the interceptor named `simulate-broken-brokers` of the plugin `io.conduktor.gateway.interceptor.chaos.SimulateBrokenBrokersPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.chaos.SimulateBrokenBrokersPlugin",
  "priority" : 100,
  "config" : {
    "rateInPercent" : 100,
    "errorMap" : {
      "FETCH" : "UNKNOWN_SERVER_ERROR",
      "PRODUCE" : "CORRUPT_MESSAGE"
    }
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-07-simulate-broken-brokers.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/simulate-broken-brokers" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-07-simulate-broken-brokers.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateBrokenBrokersPlugin",
  "priority": 100,
  "config": {
    "rateInPercent": 100,
    "errorMap": {
      "FETCH": "UNKNOWN_SERVER_ERROR",
      "PRODUCE": "CORRUPT_MESSAGE"
    }
  }
}
{
  "message": "simulate-broken-brokers is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/dsSdJVeKCFlM5LK35pBF1FEVi.svg)](https://asciinema.org/a/dsSdJVeKCFlM5LK35pBF1FEVi)

</details>

## Listing interceptors for teamA

Listing interceptors on `gateway1` for virtual cluster `teamA`

<details open>
<summary>Command</summary>



```sh
curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/teamA' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "interceptors": [
    {
      "name": "simulate-broken-brokers",
      "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateBrokenBrokersPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "rateInPercent": 100,
        "errorMap": {
          "FETCH": "UNKNOWN_SERVER_ERROR",
          "PRODUCE": "CORRUPT_MESSAGE"
        }
      }
    }
  ]
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/SVkFIg1SGgmSJ1LSfwrxpO1Wh.svg)](https://asciinema.org/a/SVkFIg1SGgmSJ1LSfwrxpO1Wh)

</details>

## Let's produce some records to our created topic and observe some errors being injected by Conduktor Gateway.

This should produce output similar to this:

```
[2023-12-19 14:08:09,150] WARN [Producer clientId=producer-1] Got error produce response with correlation id 3 on topic-partition my-topic-0, retrying (1 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2023-12-19 14:08:09,252] WARN [Producer clientId=producer-1] Got error produce response with correlation id 4 on topic-partition my-topic-0, retrying (1 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
```

<details open>
<summary>Command</summary>



```sh
kafka-producer-perf-test \
  --producer.config teamA-sa.properties \
  --record-size 10 \
  --throughput 1 \
  --num-records 10 \
  --producer-prop retries=5 \
  --topic my-topic
```



</details>
<details>
<summary>Output</summary>

```
[2024-04-10 00:06:28,616] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 5 on topic-partition my-topic-0, retrying (4 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:28,734] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 6 on topic-partition my-topic-0, retrying (3 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:28,957] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 7 on topic-partition my-topic-0, retrying (2 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:29,414] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 8 on topic-partition my-topic-0, retrying (1 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:30,171] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 9 on topic-partition my-topic-0, retrying (0 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:30,171] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 10 on topic-partition my-topic-0, retrying (4 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
org.apache.kafka.common.errors.CorruptRecordException: This message has failed its CRC checksum, exceeds the valid size, has a null key for a compacted topic, or is otherwise corrupt.
org.apache.kafka.common.errors.CorruptRecordException: This message has failed its CRC checksum, exceeds the valid size, has a null key for a compacted topic, or is otherwise corrupt.
[2024-04-10 00:06:31,102] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 12 on topic-partition my-topic-0, retrying (3 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:31,102] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 13 on topic-partition my-topic-0, retrying (4 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:31,339] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 14 on topic-partition my-topic-0, retrying (2 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:31,780] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 15 on topic-partition my-topic-0, retrying (1 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:32,660] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 16 on topic-partition my-topic-0, retrying (0 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
org.apache.kafka.common.errors.CorruptRecordException: This message has failed its CRC checksum, exceeds the valid size, has a null key for a compacted topic, or is otherwise corrupt.
[2024-04-10 00:06:33,681] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 18 on topic-partition my-topic-0, retrying (3 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:33,682] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 19 on topic-partition my-topic-0, retrying (4 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:33,920] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 20 on topic-partition my-topic-0, retrying (2 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:34,379] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 21 on topic-partition my-topic-0, retrying (1 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:35,250] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 22 on topic-partition my-topic-0, retrying (0 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
org.apache.kafka.common.errors.CorruptRecordException: This message has failed its CRC checksum, exceeds the valid size, has a null key for a compacted topic, or is otherwise corrupt.
[2024-04-10 00:06:36,283] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 24 on topic-partition my-topic-0, retrying (3 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:36,284] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 25 on topic-partition my-topic-0, retrying (4 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:36,539] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 26 on topic-partition my-topic-0, retrying (2 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:36,982] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 27 on topic-partition my-topic-0, retrying (1 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:37,911] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 28 on topic-partition my-topic-0, retrying (0 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
org.apache.kafka.common.errors.CorruptRecordException: This message has failed its CRC checksum, exceeds the valid size, has a null key for a compacted topic, or is otherwise corrupt.
org.apache.kafka.common.errors.CorruptRecordException: This message has failed its CRC checksum, exceeds the valid size, has a null key for a compacted topic, or is otherwise corrupt.
org.apache.kafka.common.errors.CorruptRecordException: This message has failed its CRC checksum, exceeds the valid size, has a null key for a compacted topic, or is otherwise corrupt.
[2024-04-10 00:06:38,939] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 30 on topic-partition my-topic-0, retrying (3 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:38,941] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 31 on topic-partition my-topic-0, retrying (4 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:39,161] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 32 on topic-partition my-topic-0, retrying (2 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:39,618] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 33 on topic-partition my-topic-0, retrying (1 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:40,483] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 34 on topic-partition my-topic-0, retrying (0 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
org.apache.kafka.common.errors.CorruptRecordException: This message has failed its CRC checksum, exceeds the valid size, has a null key for a compacted topic, or is otherwise corrupt.
org.apache.kafka.common.errors.CorruptRecordException: This message has failed its CRC checksum, exceeds the valid size, has a null key for a compacted topic, or is otherwise corrupt.
[2024-04-10 00:06:41,519] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 36 on topic-partition my-topic-0, retrying (3 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:41,764] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 37 on topic-partition my-topic-0, retrying (2 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:42,221] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 38 on topic-partition my-topic-0, retrying (1 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
[2024-04-10 00:06:43,107] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 39 on topic-partition my-topic-0, retrying (0 attempts left). Error: CORRUPT_MESSAGE (org.apache.kafka.clients.producer.internals.Sender)
org.apache.kafka.common.errors.CorruptRecordException: This message has failed its CRC checksum, exceeds the valid size, has a null key for a compacted topic, or is otherwise corrupt.
0 records sent, 0,000000 records/sec (0,00 MB/sec), NaN ms avg latency, 0,00 ms max latency, 0 ms 50th, 0 ms 95th, 0 ms 99th, 0 ms 99.9th.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/7FPaRV9wMb2My10E0XCtd1fas.svg)](https://asciinema.org/a/7FPaRV9wMb2My10E0XCtd1fas)

</details>

## Remove interceptor simulate-broken-brokers

Let's delete the interceptor simulate-broken-brokers so we can stop chaos injection

<details open>
<summary>Command</summary>



```sh
curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/simulate-broken-brokers" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
```



</details>
<details>
<summary>Output</summary>

```json

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/roF0AKtMphazd9d1h0pB7dAqH.svg)](https://asciinema.org/a/roF0AKtMphazd9d1h0pB7dAqH)

</details>

## Listing interceptors for teamA

Listing interceptors on `gateway1` for virtual cluster `teamA`

<details open>
<summary>Command</summary>



```sh
curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/teamA' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "interceptors": []
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/IRRg9CCkswIqcdjpYlnrWEjga.svg)](https://asciinema.org/a/IRRg9CCkswIqcdjpYlnrWEjga)

</details>

## Let's produce some records to our created topic with no chaos



<details open>
<summary>Command</summary>



```sh
kafka-producer-perf-test \
  --producer.config teamA-sa.properties \
  --record-size 10 \
  --throughput 1 \
  --num-records 10 \
  --topic my-topic
```



</details>
<details>
<summary>Output</summary>

```
7 records sent, 1,3 records/sec (0,00 MB/sec), 56,7 ms avg latency, 259,0 ms max latency.
10 records sent, 1,077702 records/sec (0,00 MB/sec), 43,60 ms avg latency, 259,00 ms max latency, 18 ms 50th, 259 ms 95th, 259 ms 99th, 259 ms 99.9th.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/yZtitt2oGX44FX8prmNlYyOQY.svg)](https://asciinema.org/a/yZtitt2oGX44FX8prmNlYyOQY)

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
 Container kafka-client  Stopping
 Container schema-registry  Stopping
 Container gateway1  Stopping
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
 Container kafka2  Stopping
 Container kafka3  Stopping
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
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
 Network chaos-simulate-broken-broker_default  Removing
 Network chaos-simulate-broken-broker_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/l9T5usIyKUlcX89eIryHtfvN3.svg)](https://asciinema.org/a/l9T5usIyKUlcX89eIryHtfvN3)

</details>

# Conclusion

Yes, Chaos Simulate Broken Brokers is simple as it!

