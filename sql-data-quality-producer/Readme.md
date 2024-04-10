# What is SQL Data quality producer?

Use sql definition to assert data quality before being produced.

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/5YQHt3unOCjNEtoAnTEbA2y3g.svg)](https://asciinema.org/a/5YQHt3unOCjNEtoAnTEbA2y3g)

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
 Network sql-data-quality-producer_default  Creating
 Network sql-data-quality-producer_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container kafka-client  Created
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka1  Creating
 Container kafka2  Creating
 Container kafka1  Created
 Container kafka2  Created
 Container kafka3  Created
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Creating
 Container gateway1  Created
 Container gateway2  Created
 Container schema-registry  Created
 Container zookeeper  Starting
 Container kafka-client  Starting
 Container kafka-client  Started
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container kafka2  Started
 Container kafka1  Started
 Container kafka3  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka2  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka1  Healthy
 Container gateway2  Starting
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container schema-registry  Started
 Container gateway1  Started
 Container gateway2  Started
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka-client  Healthy
 Container zookeeper  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Ap3f9c3nNsVDiuzOjWjXuoJHE.svg)](https://asciinema.org/a/Ap3f9c3nNsVDiuzOjWjXuoJHE)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ4MzcxMn0.tLGKqdV7qhQ1C_BoO1nepMesNQNgKaojH24eBsXW3Go';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/BwVzLB3BXkTc4ZuBjqt8F52A9.svg)](https://asciinema.org/a/BwVzLB3BXkTc4ZuBjqt8F52A9)

</details>

## Creating topic cars on teamA

Creating on `teamA`:

* Topic `cars` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
```



</details>
<details>
<summary>Output</summary>

```
Created topic cars.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Nq3PjZE0kojte6mTkMhfYCc0n.svg)](https://asciinema.org/a/Nq3PjZE0kojte6mTkMhfYCc0n)

</details>

## Adding interceptor cars-quality

Let's create an interceptor to ensure the data produced is valid.

Creating the interceptor named `cars-quality` of the plugin `io.conduktor.gateway.interceptor.safeguard.DataQualityProducerPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.DataQualityProducerPlugin",
  "priority" : 100,
  "config" : {
    "statement" : "SELECT * FROM cars WHERE color = 'red' and record.key.year > 2020",
    "action" : "BLOCK_WHOLE_BATCH",
    "deadLetterTopic" : "dead-letter-topic"
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-07-cars-quality.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/cars-quality" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-07-cars-quality.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.DataQualityProducerPlugin",
  "priority": 100,
  "config": {
    "statement": "SELECT * FROM cars WHERE color = 'red' and record.key.year > 2020",
    "action": "BLOCK_WHOLE_BATCH",
    "deadLetterTopic": "dead-letter-topic"
  }
}
{
  "message": "cars-quality is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/PsNg7DRFxof1ajszGyT14WxZl.svg)](https://asciinema.org/a/PsNg7DRFxof1ajszGyT14WxZl)

</details>

## Producing an invalid car

Produce invalid record to the cars topic (record is not produced because color is not red)

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "type" : "SUV",
  "price" : 2000,
  "color" : "blue"
}
```
with


```sh
echo '{"type":"SUV","price":2000,"color":"blue"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> org.apache.kafka.common.errors.PolicyViolationException:
>> Request parameters do not satisfy the configured policy: Data quality policy is violated.
> ```





</details>
<details>
<summary>Output</summary>

```
[2024-04-10 04:08:35,463] ERROR Error when sending message to topic cars with key: null, value: 42 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy: Data quality policy is violated.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/0k43ezUJfcAHnfIueUKh4nNUf.svg)](https://asciinema.org/a/0k43ezUJfcAHnfIueUKh4nNUf)

</details>

## Producing an invalid car based on key

Produce invalid record to the cars topic (record is not produced because year is not > 2020)

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "key" : "{\"year\":2010,\"make\":\"BMW\"}",
  "value" : {
    "type" : "Sports",
    "price" : 1000,
    "color" : "red"
  }
}
```
with


```sh
echo '{"year":2010,"make":"BMW"}\t{"type":"Sports","price":1000,"color":"red"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --property "parse.key=true" \
        --topic cars
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> org.apache.kafka.common.errors.PolicyViolationException:
>> Request parameters do not satisfy the configured policy: Data quality policy is violated.
> ```





</details>
<details>
<summary>Output</summary>

```
[2024-04-10 04:08:36,877] ERROR Error when sending message to topic cars with key: 26 bytes, value: 44 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy: Data quality policy is violated.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/1u4N9mzZRmNxkrU8fqJLeGrf4.svg)](https://asciinema.org/a/1u4N9mzZRmNxkrU8fqJLeGrf4)

</details>

## Producing a valid car

Produce valid record to the cars topic

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "headers" : {
    "X-HEADER-1" : "value1",
    "X-HEADER-2" : "value2"
  },
  "key" : "{\"year\":2023,\"make\":\"Vinfast\"}",
  "value" : {
    "type" : "Trucks",
    "price" : 2500,
    "color" : "red"
  }
}
```
with


```sh
echo 'X-HEADER-1:value1,X-HEADER-2:value2\t{"year":2023,"make":"Vinfast"}\t{"type":"Trucks","price":2500,"color":"red"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --property "parse.key=true" \
        --property "parse.headers=true" \
        --topic cars
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/cgUKejPyvbs2IhHr6morfKuL5.svg)](https://asciinema.org/a/cgUKejPyvbs2IhHr6morfKuL5)

</details>

## Consuming from cars

Let's confirm just one record is there by consuming from the cars topic.

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 10000 \
    --property print.key=true \
    --property print.headers=true | jq
```


returns 1 event
```json
{
  "headers" : {
    "X-HEADER-1" : "value1",
    "X-HEADER-2" : "value2"
  },
  "key" : "{\"year\":2023,\"make\":\"Vinfast\"}",
  "value" : {
    "type" : "Trucks",
    "price" : 2500,
    "color" : "red"
  }
}
```



</details>
<details>
<summary>Output</summary>

```json
jq: parse error: Invalid numeric literal at line 1, column 11
Processed a total of 1 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/weeuEshLxExHNqknMeXZeYSYe.svg)](https://asciinema.org/a/weeuEshLxExHNqknMeXZeYSYe)

</details>

## Confirm all invalid cars are in the dead letter topic

Let's confirm the invalid records are in the dead letter topic.

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:29093,localhost:29094 \
    --topic dead-letter-topic \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
    --property print.key=true \
    --property print.headers=true | jq
```


returns 2 events
```json
{
  "headers" : {
    "X-ERROR-MSG" : "Message does not match the statement [SELECT * FROM cars WHERE color = 'red' and record.key.year > 2020]",
    "X-TOPIC" : "cars",
    "X-PARTITION" : "0"
  },
  "key" : null,
  "value" : {
    "type" : "SUV",
    "price" : 2000,
    "color" : "blue"
  }
}
{
  "headers" : {
    "X-ERROR-MSG" : "Message does not match the statement [SELECT * FROM cars WHERE color = 'red' and record.key.year > 2020]",
    "X-TOPIC" : "cars",
    "X-PARTITION" : "0"
  },
  "key" : "{\"year\":2010,\"make\":\"BMW\"}",
  "value" : {
    "type" : "Sports",
    "price" : 1000,
    "color" : "red"
  }
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 04:08:41,900] WARN [Consumer clientId=console-consumer, groupId=console-consumer-7741] Connection to node -3 (localhost/127.0.0.1:29094) could not be established. Node may not be available. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 04:08:41,900] WARN [Consumer clientId=console-consumer, groupId=console-consumer-7741] Bootstrap broker localhost:29094 (id: -3 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)
[2024-04-10 04:08:42,088] WARN [Consumer clientId=console-consumer, groupId=console-consumer-7741] Connection to node -2 (localhost/127.0.0.1:29093) could not be established. Node may not be available. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 04:08:42,089] WARN [Consumer clientId=console-consumer, groupId=console-consumer-7741] Bootstrap broker localhost:29093 (id: -2 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)
jq: parse error: Invalid numeric literal at line 1, column 12
Processed a total of 2 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/V0ZLCkvWUv9PvIUlmpPHs75XX.svg)](https://asciinema.org/a/V0ZLCkvWUv9PvIUlmpPHs75XX)

</details>

## Check in the audit log that messages denial were captured

Check in the audit log that messages denial were captured in cluster `kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:29093,localhost:29094 \
    --topic _conduktor_gateway_auditlogs \
    --from-beginning \
    --timeout-ms 3000 \| jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.DataQualityProducerInterceptor")'
```


returns 2 events
```json
{
  "id" : "b2693ce3-caf0-4d91-9b93-2859471f59b3",
  "source" : "krn://cluster=nSt2mo06R-2NR0ooxfyFlA",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:34776"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-10T00:08:00.329972388Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.DataQualityProducerInterceptor",
    "message" : "Request parameters do not satisfy the configured policy: Data quality policy is violated."
  }
}
{
  "id" : "d94ee6e1-cbb8-43f1-bdc6-c510bc5c2331",
  "source" : "krn://cluster=nSt2mo06R-2NR0ooxfyFlA",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:34776"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-10T00:08:00.353672972Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.DataQualityProducerInterceptor",
    "message" : "Request parameters do not satisfy the configured policy: Data quality policy is violated."
  }
}
```



</details>
<details>
<summary>Output</summary>

```
[2024-04-10 04:08:43,911] WARN [Consumer clientId=console-consumer, groupId=console-consumer-87708] Connection to node -3 (localhost/127.0.0.1:29094) could not be established. Node may not be available. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 04:08:43,911] WARN [Consumer clientId=console-consumer, groupId=console-consumer-87708] Bootstrap broker localhost:29094 (id: -3 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)
[2024-04-10 04:08:44,018] WARN [Consumer clientId=console-consumer, groupId=console-consumer-87708] Connection to node -2 (localhost/127.0.0.1:29093) could not be established. Node may not be available. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 04:08:44,018] WARN [Consumer clientId=console-consumer, groupId=console-consumer-87708] Bootstrap broker localhost:29093 (id: -2 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)
{"id":"6c7f6860-4403-4253-b13c-3fc51d977632","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.48.8:8888","remoteAddress":"192.168.65.1:46656"},"specVersion":"0.1.0","time":"2024-04-10T00:08:32.650267792Z","eventData":{"method":"POST","path":"/admin/vclusters/v1/vcluster/teamA/username/sa","body":"{\"lifeTimeSeconds\": 7776000}"}}
{"id":"8e821d2b-029d-42ca-a677-4ff61beaaf3f","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6969","remoteAddress":"/192.168.65.1:35234"},"specVersion":"0.1.0","time":"2024-04-10T00:08:33.540589667Z","eventData":"SUCCESS"}
{"id":"2df26e95-7b06-4a24-9495-f074ce51594c","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6969","remoteAddress":"/192.168.65.1:35235"},"specVersion":"0.1.0","time":"2024-04-10T00:08:33.588269542Z","eventData":"SUCCESS"}
{"id":"9a58f35f-09fe-4707-aa07-f0e14a2a2777","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.48.8:8888","remoteAddress":"192.168.65.1:46659"},"specVersion":"0.1.0","time":"2024-04-10T00:08:34.210227418Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/cars-quality","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.DataQualityProducerPlugin\",  \"priority\" : 100,  \"config\" : {    \"statement\" : \"SELECT * FROM cars WHERE color = 'red' and record.key.year > 2020\",    \"action\" : \"BLOCK_WHOLE_BATCH\",    \"deadLetterTopic\" : \"dead-letter-topic\"  }}"}}
{"id":"e5661af1-cf99-4075-90c2-34b97d0e289b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6969","remoteAddress":"/192.168.65.1:35237"},"specVersion":"0.1.0","time":"2024-04-10T00:08:35.322850168Z","eventData":"SUCCESS"}
{"id":"dc94be91-b72b-4cb8-88f9-3b9d1cf62540","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6970","remoteAddress":"/192.168.65.1:51128"},"specVersion":"0.1.0","time":"2024-04-10T00:08:35.359787668Z","eventData":"SUCCESS"}
{"id":"36373c42-7493-490d-8395-d381273a9bb8","source":"krn://cluster=RMTRS07ST_mTPTcHEbuQAA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:51128"},"specVersion":"0.1.0","time":"2024-04-10T00:08:35.449398252Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.DataQualityProducerInterceptor","message":"Request parameters do not satisfy the configured policy: Data quality policy is violated."}}
{"id":"a79b073c-7122-4755-80e1-801a4787dd06","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6969","remoteAddress":"/192.168.65.1:35239"},"specVersion":"0.1.0","time":"2024-04-10T00:08:36.818979419Z","eventData":"SUCCESS"}
{"id":"46c7e5ff-2f63-4255-b448-26a6fac4072b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6970","remoteAddress":"/192.168.65.1:51130"},"specVersion":"0.1.0","time":"2024-04-10T00:08:36.855387919Z","eventData":"SUCCESS"}
{"id":"f2b184e5-a176-47b7-a16a-e0e3c2bbdd6c","source":"krn://cluster=RMTRS07ST_mTPTcHEbuQAA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:51130"},"specVersion":"0.1.0","time":"2024-04-10T00:08:36.871083794Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.DataQualityProducerInterceptor","message":"Request parameters do not satisfy the configured policy: Data quality policy is violated."}}
{"id":"3ddb65c5-27e7-4995-9a32-41a7377e2a97","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6969","remoteAddress":"/192.168.65.1:35241"},"specVersion":"0.1.0","time":"2024-04-10T00:08:38.218480295Z","eventData":"SUCCESS"}
{"id":"0b1c15f5-edd9-44cc-bd9d-3f9e8909aae1","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6970","remoteAddress":"/192.168.65.1:51132"},"specVersion":"0.1.0","time":"2024-04-10T00:08:38.263550128Z","eventData":"SUCCESS"}
{"id":"c21aee68-d965-45dc-97bd-b1260f531817","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6969","remoteAddress":"/192.168.65.1:35243"},"specVersion":"0.1.0","time":"2024-04-10T00:08:39.618044045Z","eventData":"SUCCESS"}
{"id":"bbd92249-57b8-4cef-9cf4-8163222b09fb","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6969","remoteAddress":"/192.168.65.1:35244"},"specVersion":"0.1.0","time":"2024-04-10T00:08:39.646500962Z","eventData":"SUCCESS"}
{"id":"67b76bc9-ca15-460c-8ab9-5853e54c3b25","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.48.8:6970","remoteAddress":"/192.168.65.1:51135"},"specVersion":"0.1.0","time":"2024-04-10T00:08:39.753931129Z","eventData":"SUCCESS"}
[2024-04-10 04:08:47,390] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 15 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Wcw8dTnWD0O6ICakMzq3j4geV.svg)](https://asciinema.org/a/Wcw8dTnWD0O6ICakMzq3j4geV)

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
 Container gateway2  Stopping
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
 Container kafka2  Stopping
 Container kafka3  Stopping
 Container kafka1  Stopping
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka-client  Stopped
 Container kafka-client  Removing
 Container kafka-client  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network sql-data-quality-producer_default  Removing
 Network sql-data-quality-producer_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/1DCfyHYIv0B8vIwbUNwrNc3Fd.svg)](https://asciinema.org/a/1DCfyHYIv0B8vIwbUNwrNc3Fd)

</details>

