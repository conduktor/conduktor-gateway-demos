# Field level encryption and performance

Let's demonstrate field level encryption and performance

## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/3mMSi21J5SfEV2GyD37kuu0MW.svg)](https://asciinema.org/a/3mMSi21J5SfEV2GyD37kuu0MW)

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

  ![Creating virtual cluster `teamA`](images/step-05-CREATE_VIRTUAL_CLUSTERS.gif)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcwMjk4MTMzM30.0cWIemiFK45EAMz--2VDmqQs7WuSmvTlTs0EL-rsqzY';
bootstrap.servers=localhost:6969
```

</details>

## Creating topic `customers`

Creating topic `customers` on `teamA`
* topic `customers` with partitions:1 replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic customers
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `customers`](images/step-07-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic customers.
 

```

</details>

## Adding interceptor `encrypt` in `gateway1`

We want to encrypt only two fields, with an in memory KMS.


Creating the interceptor named `encrypt` of the plugin ``io.conduktor.gateway.interceptor.EncryptPlugin using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.EncryptPlugin",
  "priority" : 100,
  "config" : {
    "fields" : [ {
      "fieldName" : "password",
      "keySecretId" : "password-secret",
      "algorithm" : {
        "type" : "AES_GCM",
        "kms" : "IN_MEMORY"
      }
    }, {
      "fieldName" : "visa",
      "keySecretId" : "visa-secret",
      "algorithm" : {
        "type" : "AES_GCM",
        "kms" : "IN_MEMORY"
      }
    } ]
  }
}
```

Here's how to send it:

```sh
curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/encrypt" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.EncryptPlugin","priority":100,"config":{"fields":[{"fieldName":"password","keySecretId":"password-secret","algorithm":{"type":"AES_GCM","kms":"IN_MEMORY"}},{"fieldName":"visa","keySecretId":"visa-secret","algorithm":{"type":"AES_GCM","kms":"IN_MEMORY"}}]}}' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `encrypt` in `gateway1`](images/step-08-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "encrypt is created"
}
 

```

</details>

## Adding interceptor `decrypt` in `gateway1`

Let's add the decrypt interceptor to decipher messages


Creating the interceptor named `decrypt` of the plugin ``io.conduktor.gateway.interceptor.DecryptPlugin using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.DecryptPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "customers",
    "kmsConfig" : {
      "vault" : {
        "uri" : "http://vault:8200",
        "token" : "vault-plaintext-root-token",
        "version" : 1
      }
    }
  }
}
```

Here's how to send it:

```sh
curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/decrypt" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.DecryptPlugin","priority":100,"config":{"topic":"customers","kmsConfig":{"vault":{"uri":"http://vault:8200","token":"vault-plaintext-root-token","version":1}}}}' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `decrypt` in `gateway1`](images/step-09-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "decrypt is created"
}
 

```

</details>

## Listing interceptors for `teamA`

Listing interceptors on `gateway1` for virtual cluster `teamA`

```sh
curl \
    --silent \
    --request GET "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptors" \
    --user "admin:conduktor" \
    --header 'Content-Type: application/json' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Listing interceptors for `teamA`](images/step-10-LIST_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "interceptors": [
    {
      "name": "decrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": null,
      "config": {
        "topic": "customers",
        "kmsConfig": {
          "vault": {
            "uri": "http://vault:8200",
            "token": "vault-plaintext-root-token",
            "version": 1
          }
        }
      }
    },
    {
      "name": "encrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": null,
      "config": {
        "fields": [
          {
            "fieldName": "password",
            "keySecretId": "password-secret",
            "algorithm": {
              "type": "AES_GCM",
              "kms": "IN_MEMORY"
            }
          },
          {
            "fieldName": "visa",
            "keySecretId": "visa-secret",
            "algorithm": {
              "type": "AES_GCM",
              "kms": "IN_MEMORY"
            }
          }
        ]
      }
    }
  ]
}
 

```

</details>

## Running `kafka-producer-perf-test` bundled with Apache Kafka



```sh
kafka-producer-perf-test \
  --topic customers \
  --throughput -1 \
  --num-records 1000000 \
  --producer-props \
      bootstrap.servers=localhost:6969 \
      linger.ms=100 \
      compression.type=lz4 \
  --producer.config teamA-sa.properties \
  --payload-file examples.json
```

<details>
  <summary>Realtime command output</summary>

  ![Running `kafka-producer-perf-test` bundled with Apache Kafka](images/step-11-SH.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Reading payloads from: /Users/framiere/conduktor/conduktor-gateway-soak-func/target/2023.09.20-09:47:20/encryption-performance/examples.json
Number of messages read: 2
10647 records sent, 2118,4 records/sec (0,25 MB/sec), 2001,0 ms avg latency, 3214,0 ms max latency.
52778 records sent, 10324,3 records/sec (1,21 MB/sec), 5395,3 ms avg latency, 7709,0 ms max latency.
64560 records sent, 12883,7 records/sec (1,51 MB/sec), 10376,6 ms avg latency, 12655,0 ms max latency.
52080 records sent, 10368,3 records/sec (1,22 MB/sec), 15159,9 ms avg latency, 17627,0 ms max latency.
85652 records sent, 17127,0 records/sec (2,01 MB/sec), 19844,5 ms avg latency, 21553,0 ms max latency.
117676 records sent, 23187,4 records/sec (2,72 MB/sec), 21402,2 ms avg latency, 23011,0 ms max latency.
127225 records sent, 24363,3 records/sec (2,86 MB/sec), 25082,1 ms avg latency, 27411,0 ms max latency.
112059 records sent, 22242,8 records/sec (2,61 MB/sec), 29226,6 ms avg latency, 31705,0 ms max latency.
106052 records sent, 21012,9 records/sec (2,46 MB/sec), 33806,4 ms avg latency, 36128,0 ms max latency.
111028 records sent, 21942,3 records/sec (2,57 MB/sec), 38069,1 ms avg latency, 40379,0 ms max latency.
102145 records sent, 19153,4 records/sec (2,25 MB/sec), 42053,5 ms avg latency, 44905,0 ms max latency.
51616 records sent, 10196,8 records/sec (1,20 MB/sec), 47157,5 ms avg latency, 49402,0 ms max latency.
1000000 records sent, 16319,070466 records/sec (1,91 MB/sec), 27312,37 ms avg latency, 49544,00 ms max latency, 26806 ms 50th, 45563 ms 95th, 49345 ms 99th, 49536 ms 99.9th.
 

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

  ![Cleanup the docker environment](images/step-12-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

# Conclusion

Yes, encryption in the Kafka world can be simple ... and efficient!

> [!NOTE]
> The best part is that this performance level is with the default security provider.
> You can use Bouncy Castle, Conscrypt etc to boost both your performance and compliancy!

