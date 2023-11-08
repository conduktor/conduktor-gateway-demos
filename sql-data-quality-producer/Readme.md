# What is SQL Data quality producer?

Use sql definition to assert data quality before being produced.

## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/bxkl1tw1rx0zBuu0pnal6JeoI.svg)](https://asciinema.org/a/bxkl1tw1rx0zBuu0pnal6JeoI)

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
gateway1          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway1          16 minutes ago   Up 16 minutes (healthy)   0.0.0.0:6969-6971->6969-6971/tcp, 0.0.0.0:8888->8888/tcp
gateway2          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway2          16 minutes ago   Up 16 minutes (healthy)   0.0.0.0:7969-7971->7969-7971/tcp, 0.0.0.0:8889->8888/tcp
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            16 minutes ago   Up 16 minutes (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            16 minutes ago   Up 16 minutes (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
kafka3            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka3            16 minutes ago   Up 16 minutes (healthy)   9092/tcp, 0.0.0.0:19094->19094/tcp
schema-registry   confluentinc/cp-schema-registry:latest   "/etc/confluent/dock…"   schema-registry   16 minutes ago   Up 16 minutes (healthy)   0.0.0.0:8081->8081/tcp
zookeeper         confluentinc/cp-zookeeper:latest         "/etc/confluent/dock…"   zookeeper         16 minutes ago   Up 16 minutes (healthy)   2181/tcp, 2888/tcp, 3888/tcp

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
 Container zookeeper  Creating
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka1  Creating
 Container kafka2  Creating
 Container kafka2  Created
 Container kafka3  Created
 Container kafka1  Created
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Creating
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway1  Created
 Container gateway2  Created
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
 Container kafka3  Started
 Container kafka2  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container gateway2  Starting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka3  Healthy
 Container schema-registry  Starting
 Container gateway1  Started
 Container schema-registry  Started
 Container gateway2  Started
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container zookeeper  Healthy
 Container schema-registry  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy

```

</details>
      


## Creating virtual cluster `teamA`

Creating virtual cluster `teamA` on gateway `gateway1`

```sh
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
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

  ![Creating virtual cluster `teamA`](images/step-05-CREATE_VIRTUAL_CLUSTER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")
curl     --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa"     --header 'Content-Type: application/json'     --user 'admin:conduktor'     --silent     --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token"

echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > teamA-sa.properties

```

</details>
      


### Review the kafka properties to connect to `teamA`

Review the kafka properties to connect to `teamA`

```sh
cat teamA-sa.properties
```

<details on>
  <summary>File content</summary>

```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzc0ODQyMH0.zh6_1rnHImBJJZvKa9e54_dT_tCnDMqEVuLBZHywj68';
bootstrap.servers=localhost:6969
```

</details>


## Creating topic `cars` on `teamA`

Creating topic `cars` on `teamA`
* Topic `cars` with partitions:1 and replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `cars` on `teamA`](images/step-07-CREATE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
Created topic cars.

```

</details>
      


## Adding interceptor `myDataQualityProducer`

Let's create an interceptor to ensure the data produced is valid.


Creating the interceptor named `myDataQualityProducer` of the plugin `io.conduktor.gateway.interceptor.DataQualityProducerPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.DataQualityProducerPlugin",
  "priority" : 100,
  "config" : {
    "statement" : "SELECT * FROM cars WHERE color = 'red' and record.key.year > 2020",
    "action" : "BLOCK_WHOLE_BATCH",
    "deadLetterTopic" : "dead-letter-topic"
  }
}
```

Here's how to send it:

```sh
cat step-08-myDataQualityProducer.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/myDataQualityProducer" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-myDataQualityProducer.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `myDataQualityProducer`](images/step-08-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-08-myDataQualityProducer.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.DataQualityProducerPlugin",
  "priority": 100,
  "config": {
    "statement": "SELECT * FROM cars WHERE color = 'red' and record.key.year > 2020",
    "action": "BLOCK_WHOLE_BATCH",
    "deadLetterTopic": "dead-letter-topic"
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/myDataQualityProducer" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-myDataQualityProducer.json | jq
{
  "message": "myDataQualityProducer is created"
}

```

</details>
      


## Producing 1 message in `cars`

Produce invalid record to the cars topic (record is not produced because year is not > 2020)

```sh
echo '{"type":"Sports","price":1000,"color":"red"}' | \
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



<details>
  <summary>Realtime command output</summary>

  ![Producing 1 message in `cars`](images/step-09-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"type":"Sports","price":1000,"color":"red"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars

```

</details>
      


## Producing 1 message in `cars`

Produce invalid record to the cars topic (record is not produced because color is not red)

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



<details>
  <summary>Realtime command output</summary>

  ![Producing 1 message in `cars`](images/step-10-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"type":"SUV","price":2000,"color":"blue"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars
[2024-01-23 02:14:18,167] ERROR Error when sending message to topic cars with key: null, value: 42 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy: Data quality policy is violated.

```

</details>
      


## Check in the audit log that message was denied

Check in the audit log that message was denied in cluster `kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:29093,localhost:29094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.DataQualityProducerInterceptor")'
```


```json
{
  "id" : "9bab0522-2f33-4efc-a4d8-8fb42000f50f",
  "source" : "krn://cluster=xqjgBts1TCOZWlCzY3J-Ew",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:29086"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-23T01:13:41.547551547Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.DataQualityProducerInterceptor",
    "message" : "Request parameters do not satisfy the configured policy: Data quality policy is violated."
  }
}
{
  "id" : "8a21e0bf-f145-4182-aaef-bb764e80a090",
  "source" : "krn://cluster=xqjgBts1TCOZWlCzY3J-Ew",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:29086"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-23T01:13:41.570223255Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.DataQualityProducerInterceptor",
    "message" : "Request parameters do not satisfy the configured policy: Data quality policy is violated."
  }
}
```


<details>
  <summary>Realtime command output</summary>

  ![Check in the audit log that message was denied](images/step-11-AUDITLOG.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:29093,localhost:29094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.DataQualityProducerInterceptor")'
[2024-01-23 02:14:19,341] WARN [Consumer clientId=console-consumer, groupId=console-consumer-21214] Connection to node -3 (localhost/127.0.0.1:29094) could not be established. Broker may not be available. (org.apache.kafka.clients.NetworkClient)
[2024-01-23 02:14:19,341] WARN [Consumer clientId=console-consumer, groupId=console-consumer-21214] Bootstrap broker localhost:29094 (id: -3 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)
[2024-01-23 02:14:22,567] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 9 messages
{
  "id": "ac3e42a2-611f-4c0b-bce0-3ba7de61a5df",
  "source": "krn://cluster=kk0VWCjWSCeOmCDgRYmWVw",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:29369"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-23T01:14:18.150366758Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.DataQualityProducerInterceptor",
    "message": "Request parameters do not satisfy the configured policy: Data quality policy is violated."
  }
}

```

</details>
      


## Producing 1 message in `cars`

Produce valid record to the cars topic

```sh
echo '{"type":"Trucks","price":2500,"color":"red"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars
```

<details>
  <summary>Realtime command output</summary>

  ![Producing 1 message in `cars`](images/step-12-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"type":"Trucks","price":2500,"color":"red"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars

```

</details>
      


## Consuming from `cars`

Let's confirm just one record is there by consuming from the `cars` topic.

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `cars`](images/step-13-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 10000 \
 | jq
Processed a total of 1 messages
{
  "type": "Sports",
  "price": 1000,
  "color": "red"
}

```

</details>
      


## Consuming from `dead-letter-topic`

Let's confirm the invalid records are in the dead letter topic.

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:29093,localhost:29094 \
    --topic dead-letter-topic \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `dead-letter-topic`](images/step-14-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:29093,localhost:29094 \
    --topic dead-letter-topic \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
 | jq
[2024-01-23 02:14:37,292] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "type": "SUV",
  "price": 2000,
  "color": "blue"
}

```

</details>
      


