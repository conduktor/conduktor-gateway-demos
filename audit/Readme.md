# What does audit do?



## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/fZdBXQAZ2eSj7Z77uPqPsvvPI.svg)](https://asciinema.org/a/fZdBXQAZ2eSj7Z77uPqPsvvPI)

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
gateway1          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway1          33 seconds ago   Up 16 seconds (healthy)   0.0.0.0:6969-6971->6969-6971/tcp, 0.0.0.0:8888->8888/tcp
gateway2          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway2          33 seconds ago   Up 16 seconds (healthy)   0.0.0.0:7969-7971->7969-7971/tcp, 0.0.0.0:8889->8888/tcp
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            33 seconds ago   Up 27 seconds (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            33 seconds ago   Up 27 seconds (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
kafka3            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka3            33 seconds ago   Up 27 seconds (healthy)   9092/tcp, 0.0.0.0:19094->19094/tcp
schema-registry   confluentinc/cp-schema-registry:latest   "/etc/confluent/dock…"   schema-registry   33 seconds ago   Up 16 seconds (healthy)   0.0.0.0:8081->8081/tcp
zookeeper         confluentinc/cp-zookeeper:latest         "/etc/confluent/dock…"   zookeeper         33 seconds ago   Up 32 seconds (healthy)   2181/tcp, 2888/tcp, 3888/tcp

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
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka1  Created
 Container kafka2  Created
 Container kafka3  Created
 Container gateway1  Creating
 Container gateway2  Creating
 Container schema-registry  Creating
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container schema-registry  Created
 Container gateway1  Created
 Container gateway2  Created
 Container zookeeper  Starting
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
 Container kafka3  Started
 Container kafka1  Started
 Container kafka2  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container gateway1  Starting
 Container kafka1  Healthy
 Container gateway2  Starting
 Container kafka1  Healthy
 Container schema-registry  Starting
 Container schema-registry  Started
 Container gateway1  Started
 Container gateway2  Started
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container zookeeper  Healthy
 Container schema-registry  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzcxNzA2Mn0.oWXJCVLK6FBLA_tLURYU5wlztbB9XW17adKMe1LQUy8';
bootstrap.servers=localhost:6969
```

</details>


## Adding interceptor `guard-on-produce`

Let's make sure we enforce policies also at produce time!

Here message shall be sent with compression and with the right level of resiliency


Creating the interceptor named `guard-on-produce` of the plugin `io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin",
  "priority" : 100,
  "config" : {
    "acks" : {
      "value" : [ -1 ],
      "action" : "BLOCK"
    },
    "compressions" : {
      "value" : [ "NONE", "GZIP" ],
      "action" : "BLOCK"
    }
  }
}
```

Here's how to send it:

```sh
cat step-07-guard-on-produce.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-produce" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-07-guard-on-produce.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `guard-on-produce`](images/step-07-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-07-guard-on-produce.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin",
  "priority": 100,
  "config": {
    "acks": {
      "value": [
        -1
      ],
      "action": "BLOCK"
    },
    "compressions": {
      "value": [
        "NONE",
        "GZIP"
      ],
      "action": "BLOCK"
    }
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-produce" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-07-guard-on-produce.json | jq
{
  "message": "guard-on-produce is created"
}

```

</details>
      


## Listing interceptors for `teamA`

Listing interceptors on `gateway1` for virtual cluster `teamA`

```sh
curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/teamA' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Listing interceptors for `teamA`](images/step-08-LIST_INTERCEPTORS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/teamA' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
{
  "interceptors": [
    {
      "name": "guard-on-produce",
      "pluginClass": "io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "acks": {
          "value": [
            -1
          ],
          "action": "BLOCK"
        },
        "compressions": {
          "value": [
            "NONE",
            "GZIP"
          ],
          "action": "BLOCK"
        }
      }
    }
  ]
}

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

  ![Creating topic `cars` on `teamA`](images/step-09-CREATE_TOPICS.gif)

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
      


## Produce sample data to our `cars` topic without the right policies

Produce 1 record ... that do not match our policy

```sh
echo '{"type":"Fiat","color":"red","price":-1}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --request-required-acks 1 \
        --compression-codec snappy \
        --topic cars
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> org.apache.kafka.common.errors.PolicyViolationException:
>> Request parameters do not satisfy the configured policy.
>>Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1.
>>Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]
> ```



<details>
  <summary>Realtime command output</summary>

  ![Produce sample data to our `cars` topic without the right policies](images/step-10-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"type":"Fiat","color":"red","price":-1}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --request-required-acks 1 \
        --compression-codec snappy \
        --topic cars
[2024-01-22 17:31:45,577] ERROR Error when sending message to topic cars with key: null, value: 40 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1. Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]

```

</details>
      


## Check in the audit log that produce was denied

Check in the audit log that produce was denied in cluster `kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin")'
```


```json
{
  "id" : "b1bc11b1-2557-4dd2-b9a4-6c16150d119a",
  "source" : "krn://cluster=Kjwmzd5aQnS-TcV07egE9Q",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:26786"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T16:31:03.965457252Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin",
    "message" : "Request parameters do not satisfy the configured policy. Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1. Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]"
  }
}
```


<details>
  <summary>Realtime command output</summary>

  ![Check in the audit log that produce was denied](images/step-11-AUDITLOG.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin")'
[2024-01-22 17:31:50,179] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 8 messages
{
  "id": "216b743a-379d-489d-b2ae-8dac2b2d27b9",
  "source": "krn://cluster=zRvhZfWOT3qVJ0X3WpaE1A",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:57067"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T16:31:45.555120841Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin",
    "message": "Request parameters do not satisfy the configured policy. Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1. Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]"
  }
}

```

</details>
      


