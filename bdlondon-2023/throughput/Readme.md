# How about the throughput impact?



## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/D6ynhuIEEHR3vJl8ORpYBFP1Q.svg)](https://asciinema.org/a/D6ynhuIEEHR3vJl8ORpYBFP1Q)

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

## Creating topic `physical-kafka`

Creating topic `physical-kafka` on `kafka1`
* topic `physical-kafka` with partitions:10 replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --replication-factor 1 \
    --partitions 10 \
    --create --if-not-exists \
    --topic physical-kafka
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `physical-kafka`](images/step-05-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic physical-kafka.
 

```

</details>

## Let's use `kafka-producer-perf-test` that comes bundled with Kafka

`throughput` is set to -1 to disable throttling and create the maximum pain

```sh
kafka-producer-perf-test \
    --topic physical-kafka \
    --throughput -1 \
    --num-records 2500000 \
    --record-size 255 \
    --producer-props bootstrap.servers=localhost:29092,localhost:29093,localhost:29094
```

<details>
  <summary>Realtime command output</summary>

  ![Let's use `kafka-producer-perf-test` that comes bundled with Kafka](images/step-06-SH.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
396989 records sent, 79397,8 records/sec (19,31 MB/sec), 1215,0 ms avg latency, 2305,0 ms max latency.
672159 records sent, 134404,9 records/sec (32,69 MB/sec), 897,3 ms avg latency, 1365,0 ms max latency.
554734 records sent, 110946,8 records/sec (26,98 MB/sec), 1216,0 ms avg latency, 1903,0 ms max latency.
2500000 records sent, 134683,762526 records/sec (32,75 MB/sec), 865,53 ms avg latency, 2305,00 ms max latency, 833 ms 50th, 1663 ms 95th, 2052 ms 99th, 2290 ms 99.9th.
 

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

  ![Creating virtual cluster `teamA`](images/step-07-CREATE_VIRTUAL_CLUSTERS.gif)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcwMjk4MTg5Mn0.85nGIVd25rKcPQSUfdubRqfvoq4n64P6V9gL-WHPNvE';
bootstrap.servers=localhost:6969
```

</details>

## Creating topic `via-gateway`

Creating topic `via-gateway` on `teamA`
* topic `via-gateway` with partitions:10 replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 10 \
    --create --if-not-exists \
    --topic via-gateway
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `via-gateway`](images/step-09-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic via-gateway.
 

```

</details>

## Let's use `kafka-producer-perf-test` that comes bundled with Kafka

`throughput` is set to -1 to disable throttling and create the maximum pain

```sh
kafka-producer-perf-test \
    --topic via-gateway \
    --throughput -1 \
    --num-records 2500000 \
    --record-size 255 \
    --producer-props bootstrap.servers=localhost:6969 \
    --producer.config teamA-sa.properties
```

<details>
  <summary>Realtime command output</summary>

  ![Let's use `kafka-producer-perf-test` that comes bundled with Kafka](images/step-10-SH.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
163420 records sent, 32573,3 records/sec (7,92 MB/sec), 2513,1 ms avg latency, 3846,0 ms max latency.
419253 records sent, 83766,8 records/sec (20,37 MB/sec), 1657,6 ms avg latency, 2847,0 ms max latency.
488183 records sent, 97617,1 records/sec (23,74 MB/sec), 1303,2 ms avg latency, 1936,0 ms max latency.
576023 records sent, 115204,6 records/sec (28,02 MB/sec), 1088,5 ms avg latency, 1414,0 ms max latency.
473299 records sent, 94527,5 records/sec (22,99 MB/sec), 1283,5 ms avg latency, 1929,0 ms max latency.
2500000 records sent, 90155,066715 records/sec (21,92 MB/sec), 1333,09 ms avg latency, 3846,00 ms max latency, 1234 ms 50th, 2362 ms 95th, 3563 ms 99th, 3796 ms 99.9th.
 

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

  ![Cleanup the docker environment](images/step-11-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

# Conclusion

Gateway is fast enough for all use cases!

