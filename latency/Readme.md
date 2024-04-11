# How about the latency impact?



## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/88s2wIb9RRrb1jmntgoE2VAfv.svg)](https://asciinema.org/a/88s2wIb9RRrb1jmntgoE2VAfv)

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
 Network latency_default  Creating
 Network latency_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container kafka-client  Created
 Container zookeeper  Created
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka3  Creating
 Container kafka1  Created
 Container kafka3  Created
 Container kafka2  Created
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Creating
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container zookeeper  Starting
 Container kafka-client  Starting
 Container kafka-client  Started
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container kafka2  Started
 Container kafka1  Started
 Container kafka3  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container gateway1  Starting
 Container kafka3  Healthy
 Container gateway2  Starting
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container schema-registry  Starting
 Container gateway1  Started
 Container schema-registry  Started
 Container gateway2  Started
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka-client  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container zookeeper  Healthy
 Container schema-registry  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/4NTlePh1ySKRmsO9o3hlLyvU3.svg)](https://asciinema.org/a/4NTlePh1ySKRmsO9o3hlLyvU3)

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

[![asciicast](https://asciinema.org/a/D3fGfLPs78pUX6XZzyotVBhp1.svg)](https://asciinema.org/a/D3fGfLPs78pUX6XZzyotVBhp1)

</details>

## Let's use EndToEndLatency that comes bundled with Kafka

arg1: broker_list 
arg2: topic 
arg3: num_messages 
arg4: producer_acks
arg5: message_size_bytes

<details open>
<summary>Command</summary>



```sh
kafka-run-class kafka.tools.EndToEndLatency \
    localhost:19092,localhost:19093,localhost:19094 \
    physical-kafka 10000 all 255
```



</details>
<details>
<summary>Output</summary>

```
WARNING: The 'kafka.tools' package is deprecated and will change to 'org.apache.kafka.tools' in the next major release.
0	47.436082999999996
1000	3.0687919999999997
2000	1.7105409999999999
3000	1.9645
4000	1.258417
5000	1.179958
6000	1.061375
7000	0.779625
8000	3.82475
9000	0.947708
Avg latency: 1,8176 ms
Percentiles: 50th = 1, 99th = 8, 99.9th = 24

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/2eobsEjPVeL0rKXd6L9DGwWEP.svg)](https://asciinema.org/a/2eobsEjPVeL0rKXd6L9DGwWEP)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ3NzYzN30.hgWWOZ0NO2YCqrFBhWC0Sonpn2PSg6R4FmVdYeZSIMs';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/LxjZs3SmIe0DUGYe4WRI7s5Ut.svg)](https://asciinema.org/a/LxjZs3SmIe0DUGYe4WRI7s5Ut)

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

[![asciicast](https://asciinema.org/a/g3W00a7NgpFGhb9gtW2KEUcUf.svg)](https://asciinema.org/a/g3W00a7NgpFGhb9gtW2KEUcUf)

</details>

## Let's use kafka-producer-perf-test that comes bundled with Kafka

arg1: broker_list 
arg2: topic 
arg3: num_messages 
arg4: producer_acks
arg5: message_size_bytes
arg6: property file

<details open>
<summary>Command</summary>



```sh
kafka-run-class kafka.tools.EndToEndLatency \
    localhost:6969 \
    via-gateway 10000 all 255 \
    teamA-sa.properties
```



</details>
<details>
<summary>Output</summary>

```
WARNING: The 'kafka.tools' package is deprecated and will change to 'org.apache.kafka.tools' in the next major release.
0	76.104875
1000	3.2898330000000002
2000	1.66875
3000	2.243625
4000	1.8816659999999998
5000	2.032
6000	1.718
7000	1.838209
8000	2.036
9000	1.6083340000000002
Avg latency: 2,6374 ms
Percentiles: 50th = 1, 99th = 12, 99.9th = 38

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/wyofDkZpzFRycyhdUT4pAsICZ.svg)](https://asciinema.org/a/wyofDkZpzFRycyhdUT4pAsICZ)

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
 Container gateway1  Stopping
 Container gateway2  Stopping
 Container kafka-client  Stopping
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka1  Stopping
 Container kafka2  Stopping
 Container kafka3  Stopping
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka-client  Stopped
 Container kafka-client  Removing
 Container kafka-client  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network latency_default  Removing
 Network latency_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/0KQypt68t57zDqcfVXb5J0vGX.svg)](https://asciinema.org/a/0KQypt68t57zDqcfVXb5J0vGX)

</details>

# Conclusion

Gateway is end to end latency is enough for all use cases!

