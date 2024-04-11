# Chaos Duplicate Messages

This interceptor injects duplicate records on produce requests.

This demo will run you through some of these use cases step-by-step.

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/dpCvjMUHH0Oi1477SEOiyN4lP.svg)](https://asciinema.org/a/dpCvjMUHH0Oi1477SEOiyN4lP)

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
 Network chaos-duplicate-messages_default  Creating
 Network chaos-duplicate-messages_default  Created
 Container kafka-client  Creating
 Container zookeeper  Creating
 Container kafka-client  Created
 Container zookeeper  Created
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka3  Creating
 Container kafka1  Created
 Container kafka3  Created
 Container kafka2  Created
 Container gateway2  Creating
 Container gateway1  Creating
 Container schema-registry  Creating
 Container gateway1  Created
 Container schema-registry  Created
 Container gateway2  Created
 Container zookeeper  Starting
 Container kafka-client  Starting
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
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container gateway2  Starting
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka1  Healthy
 Container schema-registry  Starting
 Container gateway2  Started
 Container gateway1  Started
 Container schema-registry  Started
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container kafka-client  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container zookeeper  Healthy
 Container schema-registry  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/rEQOvOLzvEV3Apq71UbtI8gs0.svg)](https://asciinema.org/a/rEQOvOLzvEV3Apq71UbtI8gs0)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ2ODg1NX0.v-EqC_w81Y2cR16Irne1iG24_SnZFvQvZLKvDXfmjxo';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/UN7euwjxJ3He9sgBpfAXOew7Y.svg)](https://asciinema.org/a/UN7euwjxJ3He9sgBpfAXOew7Y)

</details>

## Creating topic topic-duplicate on teamA

Creating on `teamA`:

* Topic `topic-duplicate` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic topic-duplicate
```



</details>
<details>
<summary>Output</summary>

```
Created topic topic-duplicate.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/o8oMdjZZ2C7VURwYSg75C8pdy.svg)](https://asciinema.org/a/o8oMdjZZ2C7VURwYSg75C8pdy)

</details>

## Adding interceptor duplicate-messages

Let's create the interceptor against the virtual cluster teamA, instructing Conduktor Gateway to inject duplicate records on produce requests.

Creating the interceptor named `duplicate-messages` of the plugin `io.conduktor.gateway.interceptor.chaos.DuplicateMessagesPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.chaos.DuplicateMessagesPlugin",
  "priority" : 100,
  "config" : {
    "rateInPercent" : 100,
    "topic" : "topic-duplicate",
    "target" : "PRODUCE"
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-07-duplicate-messages.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/duplicate-messages" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-07-duplicate-messages.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.chaos.DuplicateMessagesPlugin",
  "priority": 100,
  "config": {
    "rateInPercent": 100,
    "topic": "topic-duplicate",
    "target": "PRODUCE"
  }
}
{
  "message": "duplicate-messages is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/IeSFINYwlRjHk0G93nesCFGzu.svg)](https://asciinema.org/a/IeSFINYwlRjHk0G93nesCFGzu)

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
      "name": "duplicate-messages",
      "pluginClass": "io.conduktor.gateway.interceptor.chaos.DuplicateMessagesPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "rateInPercent": 100,
        "topic": "topic-duplicate",
        "target": "PRODUCE"
      }
    }
  ]
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/yY0fnbixRrTxWVGzAvBOLgJN7.svg)](https://asciinema.org/a/yY0fnbixRrTxWVGzAvBOLgJN7)

</details>

## Send message to our created topic

Producing 1 message in `topic-duplicate` in cluster `teamA`

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "message" : "hello world"
}
```
with


```sh
echo '{"message": "hello world"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-duplicate
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/RoUQzHXPlpB6unFw7eswqQmtm.svg)](https://asciinema.org/a/RoUQzHXPlpB6unFw7eswqQmtm)

</details>

## Let's consume the message, and confirm message was duplicated

Let's consume the message, and confirm message was duplicated in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-duplicate \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 2 events
```json
{
  "message" : "hello world"
}
{
  "message" : "hello world"
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 00:01:11,001] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "message": "hello world"
}
{
  "message": "hello world"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/oPKlARAIqGaipSj6Ca1Ko4Phy.svg)](https://asciinema.org/a/oPKlARAIqGaipSj6Ca1Ko4Phy)

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
 Container gateway1  Stopping
 Container kafka-client  Stopping
 Container schema-registry  Stopping
 Container gateway2  Stopping
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka3  Stopping
 Container kafka1  Stopping
 Container kafka2  Stopping
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
 Network chaos-duplicate-messages_default  Removing
 Network chaos-duplicate-messages_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/dQamzr1cy70SkHBIVIxS2768m.svg)](https://asciinema.org/a/dQamzr1cy70SkHBIVIxS2768m)

</details>

# Conclusion

Yes, Chaos Duplicate Messages is simple as it!

