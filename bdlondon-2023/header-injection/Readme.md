# Dynamic Header Injection & Removal

There are multiple interceptors available for manipulating headers, either injection or regex based removal. 

This demo will run you through some of these use cases step-by-step.

## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/bIOu11GsZsTe1X8QbT8QM2MA6.svg)](https://asciinema.org/a/bIOu11GsZsTe1X8QbT8QM2MA6)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcwMjk4MjgxN30.nR89yPkJ05KvXfQfZYepQB8niBun5FnPZJ0xIYSXb8g';
bootstrap.servers=localhost:6969
```

</details>

## Creating topic `users`

Creating topic `users` on `teamA`
* topic `users` with partitions:1 replication-factor:1

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

  ![Creating topic `users`](images/step-07-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic users.
 

```

</details>

## Adding interceptor `inject-headers` in `gateway1`

Let's create the interceptor to inject various headers


Creating the interceptor named `inject-headers` of the plugin ``io.conduktor.gateway.interceptor.DynamicHeaderInjectionPlugin using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.DynamicHeaderInjectionPlugin",
  "priority" : 100,
  "config" : {
    "headers" : {
      "X-MY-KEY" : "my own value",
      "X-USER" : "{{user}}",
      "X-INTERPOLATED" : "User {{user}} via ip {{userIp}}"
    }
  }
}
```

Here's how to send it:

```sh
curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/inject-headers" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.DynamicHeaderInjectionPlugin","priority":100,"config":{"headers":{"X-MY-KEY":"my own value","X-USER":"{{user}}","X-INTERPOLATED":"User {{user}} via ip {{userIp}}"}}}' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `inject-headers` in `gateway1`](images/step-08-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "inject-headers is created"
}
 

```

</details>

## Send tom and florent into `users`

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

  ![Send tom and florent into `users`](images/step-09-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Verify tom and florent have the corresponding headers

Consuming from `users` in cluster `teamA

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 5000 \
    --property print.headers=true
```

<details>
  <summary>Realtime command output</summary>

  ![Verify tom and florent have the corresponding headers](images/step-10-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
X-INTERPOLATED:User sa via ip 192.168.65.1,X-MY-KEY:my own value,X-USER:sa	{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}
X-INTERPOLATED:User sa via ip 192.168.65.1,X-MY-KEY:my own value,X-USER:sa	{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}
 

```

</details>

## Adding interceptor `remove-headers` in `gateway1`

Let's create the interceptor `remove-headers` to remove headers that match `X-MY-.*`


Creating the interceptor named `remove-headers` of the plugin ``io.conduktor.gateway.interceptor.safeguard.MessageHeaderRemovalPlugin using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.MessageHeaderRemovalPlugin",
  "priority" : 100,
  "config" : {
    "headerKeyRegex" : "X-MY-.*"
  }
}
```

Here's how to send it:

```sh
curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/remove-headers" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.safeguard.MessageHeaderRemovalPlugin","priority":100,"config":{"headerKeyRegex":"X-MY-.*"}}' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `remove-headers` in `gateway1`](images/step-11-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "remove-headers is created"
}
 

```

</details>

## Verify tom and florent have the corresponding headers

Consuming from `users` in cluster `teamA

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 5000 \
    --property print.headers=true
```

<details>
  <summary>Realtime command output</summary>

  ![Verify tom and florent have the corresponding headers](images/step-12-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
X-INTERPOLATED:User sa via ip 192.168.65.1,X-USER:sa	{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}
X-INTERPOLATED:User sa via ip 192.168.65.1,X-USER:sa	{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}
 

```

</details>

## Remove interceptor `remove-headers`

Let's delete the interceptor `remove-headers` so we can access all our headers again

```sh
curl \
    --silent \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/remove-headers" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Remove interceptor `remove-headers`](images/step-13-REMOVE_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Verify `tom` and `florent` have `X-MY-KEY` back

Consuming from `users` in cluster `teamA

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 5000 \
    --property print.headers=true
```

<details>
  <summary>Realtime command output</summary>

  ![Verify `tom` and `florent` have `X-MY-KEY` back](images/step-14-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
X-INTERPOLATED:User sa via ip 192.168.65.1,X-MY-KEY:my own value,X-USER:sa	{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}
X-INTERPOLATED:User sa via ip 192.168.65.1,X-MY-KEY:my own value,X-USER:sa	{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}
 

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

  ![Cleanup the docker environment](images/step-15-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

# Conclusion

Leveraging headers in Kafka is of tremendous help!

