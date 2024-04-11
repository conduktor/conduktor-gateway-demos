# How about the throughput impact?



## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/Zn6CEny94fAuomA31kVknPATD.svg)](https://asciinema.org/a/Zn6CEny94fAuomA31kVknPATD)

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
 Network throughput_default  Creating
 Network throughput_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container kafka-client  Created
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka3  Created
 Container kafka2  Created
 Container kafka1  Created
 Container gateway2  Creating
 Container gateway1  Creating
 Container schema-registry  Creating
 Container gateway1  Created
 Container gateway2  Created
 Container schema-registry  Created
 Container kafka-client  Starting
 Container zookeeper  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container kafka-client  Started
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container kafka2  Started
 Container kafka3  Started
 Container kafka1  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka1  Healthy
 Container schema-registry  Starting
 Container kafka1  Healthy
 Container gateway2  Starting
 Container gateway1  Started
 Container gateway2  Started
 Container schema-registry  Started
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka3  Healthy
 Container zookeeper  Healthy
 Container kafka2  Healthy
 Container kafka-client  Healthy
 Container kafka1  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/JGXBuEeY3XyTASoQMBdpr7eJX.svg)](https://asciinema.org/a/JGXBuEeY3XyTASoQMBdpr7eJX)

</details>

## Creating topic physical-kafka on kafka1

Creating on `kafka1`:

* Topic `physical-kafka` with partitions:10 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 10 \
    --create --if-not-exists \
    --topic physical-kafka
```



</details>
<details>
<summary>Output</summary>

```
Created topic physical-kafka.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/DeA1IcwJjIoVCIHy6Wv3MUzLJ.svg)](https://asciinema.org/a/DeA1IcwJjIoVCIHy6Wv3MUzLJ)

</details>

## Let's use kafka-producer-perf-test that comes bundled with Kafka

`throughput` is set to -1 to disable throttling and create the maximum pain

<details open>
<summary>Command</summary>



```sh
kafka-producer-perf-test \
    --topic physical-kafka \
    --throughput -1 \
    --num-records 2500000 \
    --record-size 255 \
    --producer-props bootstrap.servers=localhost:19092,localhost:19093,localhost:19094
```



</details>
<details>
<summary>Output</summary>

```
692839 records sent, 138457,0 records/sec (33,67 MB/sec), 323,6 ms avg latency, 852,0 ms max latency.
553186 records sent, 110615,1 records/sec (26,90 MB/sec), 315,8 ms avg latency, 942,0 ms max latency.
348127 records sent, 69625,4 records/sec (16,93 MB/sec), 1306,7 ms avg latency, 2634,0 ms max latency.
431209 records sent, 86069,7 records/sec (20,93 MB/sec), 1263,7 ms avg latency, 2899,0 ms max latency.
2500000 records sent, 103284,445363 records/sec (25,12 MB/sec), 638,35 ms avg latency, 2899,00 ms max latency, 387 ms 50th, 2051 ms 95th, 2663 ms 99th, 2788 ms 99.9th.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/dP12htVdfzrJNFDwSWMwdM2A3.svg)](https://asciinema.org/a/dP12htVdfzrJNFDwSWMwdM2A3)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ4NjE5N30.sWSMYhOOKLf7wLou5Gce9IeAlna8LUuqMmpi-3CxIPc';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/r1mKnCcUIsol6O56BUGv9tJjW.svg)](https://asciinema.org/a/r1mKnCcUIsol6O56BUGv9tJjW)

</details>

## Creating topic via-gateway on teamA

Creating on `teamA`:

* Topic `via-gateway` with partitions:10 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 10 \
    --create --if-not-exists \
    --topic via-gateway
```



</details>
<details>
<summary>Output</summary>

```
Created topic via-gateway.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/RqssIFhDjVTiZSmzBybXuDFeW.svg)](https://asciinema.org/a/RqssIFhDjVTiZSmzBybXuDFeW)

</details>

## Let's use kafka-producer-perf-test that comes bundled with Kafka

`throughput` is set to -1 to disable throttling and create the maximum pain

<details open>
<summary>Command</summary>



```sh
kafka-producer-perf-test \
    --topic via-gateway \
    --throughput -1 \
    --num-records 2500000 \
    --record-size 255 \
    --producer-props bootstrap.servers=localhost:6969 \
    --producer.config teamA-sa.properties
```



</details>
<details>
<summary>Output</summary>

```
156832 records sent, 31366,4 records/sec (7,63 MB/sec), 1507,7 ms avg latency, 2248,0 ms max latency.
370575 records sent, 73981,8 records/sec (17,99 MB/sec), 1596,6 ms avg latency, 2494,0 ms max latency.
423218 records sent, 84626,7 records/sec (20,58 MB/sec), 1574,5 ms avg latency, 2510,0 ms max latency.
428281 records sent, 85230,0 records/sec (20,73 MB/sec), 1447,0 ms avg latency, 2375,0 ms max latency.
556076 records sent, 111193,0 records/sec (27,04 MB/sec), 1054,5 ms avg latency, 2006,0 ms max latency.
2500000 records sent, 83901,063865 records/sec (20,40 MB/sec), 1174,85 ms avg latency, 2510,00 ms max latency, 1174 ms 50th, 2169 ms 95th, 2368 ms 99th, 2479 ms 99.9th.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/xYFzzRoTqZCKW012xvb019atd.svg)](https://asciinema.org/a/xYFzzRoTqZCKW012xvb019atd)

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
 Container gateway2  Stopping
 Container gateway1  Stopping
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
 Network throughput_default  Removing
 Network throughput_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/wJ9VFy5e7OjRxdIRu8rfXVIqq.svg)](https://asciinema.org/a/wJ9VFy5e7OjRxdIRu8rfXVIqq)

</details>

# Conclusion

Gateway is fast enough for all use cases!

