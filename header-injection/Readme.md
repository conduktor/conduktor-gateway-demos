# Dynamic Header Injection & Removal

There are multiple interceptors available for manipulating headers, either injection or regex based removal. 

This demo will run you through some of these use cases step-by-step.

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/kWjPbOI7tspNGq3BiKM8T6dN9.svg)](https://asciinema.org/a/kWjPbOI7tspNGq3BiKM8T6dN9)

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
 Network header-injection_default  Creating
 Network header-injection_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container zookeeper  Created
 Container kafka1  Creating
 Container kafka3  Creating
 Container kafka2  Creating
 Container kafka-client  Created
 Container kafka2  Created
 Container kafka3  Created
 Container kafka1  Created
 Container schema-registry  Creating
 Container gateway2  Creating
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
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container kafka2  Started
 Container kafka3  Started
 Container kafka1  Started
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container gateway1  Starting
 Container kafka3  Healthy
 Container schema-registry  Starting
 Container kafka2  Healthy
 Container gateway2  Starting
 Container schema-registry  Started
 Container gateway2  Started
 Container gateway1  Started
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka-client  Healthy
 Container kafka3  Healthy
 Container zookeeper  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/qozPL6m1DgyIveEJLsf3xfKE8.svg)](https://asciinema.org/a/qozPL6m1DgyIveEJLsf3xfKE8)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ3NjQ3MH0.hoxPqEUpXmMu_zwYCZVZlK5_NWDVoREkUtvxjeJoTZA';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/8j60jnBwXK67dTaoRekPZyF3i.svg)](https://asciinema.org/a/8j60jnBwXK67dTaoRekPZyF3i)

</details>

## Creating topic users on teamA

Creating on `teamA`:

* Topic `users` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic users
```



</details>
<details>
<summary>Output</summary>

```
Created topic users.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/7ZPNky1ZsU1rptTKcZd5G1cEj.svg)](https://asciinema.org/a/7ZPNky1ZsU1rptTKcZd5G1cEj)

</details>

## Adding interceptor inject-headers

Let's create the interceptor to inject various headers

Creating the interceptor named `inject-headers` of the plugin `io.conduktor.gateway.interceptor.DynamicHeaderInjectionPlugin` using the following payload

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

<details open>
<summary>Command</summary>



```sh
cat step-07-inject-headers.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/inject-headers" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-07-inject-headers.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.DynamicHeaderInjectionPlugin",
  "priority": 100,
  "config": {
    "headers": {
      "X-MY-KEY": "my own value",
      "X-USER": "{{user}}",
      "X-INTERPOLATED": "User {{user}} via ip {{userIp}}"
    }
  }
}
{
  "message": "inject-headers is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/bklulHJpZPrio7E0j3gbnud8N.svg)](https://asciinema.org/a/bklulHJpZPrio7E0j3gbnud8N)

</details>

## Send tom and laura into users

Producing 2 messages in `users` in cluster `teamA`

<details>
<summary>Command</summary>



Sending 2 events
```json
{
  "name" : "tom",
  "username" : "tom@conduktor.io",
  "password" : "motorhead",
  "visa" : "#abc123",
  "address" : "Chancery lane, London"
}
{
  "name" : "laura",
  "username" : "laura@conduktor.io",
  "password" : "kitesurf",
  "visa" : "#888999XZ",
  "address" : "Dubai, UAE"
}
```
with


```sh
echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users

echo '{"name":"laura","username":"laura@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/uAHvo0bD5GXG0WMfTG4ZElwPe.svg)](https://asciinema.org/a/uAHvo0bD5GXG0WMfTG4ZElwPe)

</details>

## Verify tom and laura have the corresponding headers

Verify tom and laura have the corresponding headers in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
    --property print.headers=true | jq
```


returns 2 events
```json
{
  "headers" : {
    "X-INTERPOLATED" : "User sa via ip 192.168.65.1",
    "X-MY-KEY" : "my own value",
    "X-USER" : "sa"
  },
  "value" : {
    "name" : "tom",
    "username" : "tom@conduktor.io",
    "password" : "motorhead",
    "visa" : "#abc123",
    "address" : "Chancery lane, London"
  }
}
{
  "headers" : {
    "X-INTERPOLATED" : "User sa via ip 192.168.65.1",
    "X-MY-KEY" : "my own value",
    "X-USER" : "sa"
  },
  "value" : {
    "name" : "laura",
    "username" : "laura@conduktor.io",
    "password" : "kitesurf",
    "visa" : "#888999XZ",
    "address" : "Dubai, UAE"
  }
}
```



</details>
<details>
<summary>Output</summary>

```json
jq: parse error: Invalid numeric literal at line 1, column 15
Processed a total of 2 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/yCVpkCTCmoCiNtZJkLEmarG8p.svg)](https://asciinema.org/a/yCVpkCTCmoCiNtZJkLEmarG8p)

</details>

## Adding interceptor remove-headers

Let's create the interceptor `remove-headers` to remove headers that match `X-MY-.*`

Creating the interceptor named `remove-headers` of the plugin `io.conduktor.gateway.interceptor.safeguard.MessageHeaderRemovalPlugin` using the following payload

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

<details open>
<summary>Command</summary>



```sh
cat step-10-remove-headers.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/remove-headers" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-10-remove-headers.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.MessageHeaderRemovalPlugin",
  "priority": 100,
  "config": {
    "headerKeyRegex": "X-MY-.*"
  }
}
{
  "message": "remove-headers is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/fJJWTJ9J1QFAoHnxYO8XaM6ZF.svg)](https://asciinema.org/a/fJJWTJ9J1QFAoHnxYO8XaM6ZF)

</details>

## Verify tom and laura have the corresponding headers

Verify tom and laura have the corresponding headers in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
    --property print.headers=true | jq
```


returns 2 events
```json
{
  "headers" : {
    "X-INTERPOLATED" : "User sa via ip 192.168.65.1",
    "X-USER" : "sa"
  },
  "value" : {
    "name" : "tom",
    "username" : "tom@conduktor.io",
    "password" : "motorhead",
    "visa" : "#abc123",
    "address" : "Chancery lane, London"
  }
}
{
  "headers" : {
    "X-INTERPOLATED" : "User sa via ip 192.168.65.1",
    "X-USER" : "sa"
  },
  "value" : {
    "name" : "laura",
    "username" : "laura@conduktor.io",
    "password" : "kitesurf",
    "visa" : "#888999XZ",
    "address" : "Dubai, UAE"
  }
}
```



</details>
<details>
<summary>Output</summary>

```json
jq: parse error: Invalid numeric literal at line 1, column 15
Processed a total of 2 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/h3F2Tsp3jPHH6yx8Q4IyqKjCf.svg)](https://asciinema.org/a/h3F2Tsp3jPHH6yx8Q4IyqKjCf)

</details>

## Remove interceptor remove-headers

Let's delete the interceptor `remove-headers` so we can access all our headers again

<details open>
<summary>Command</summary>



```sh
curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/remove-headers" \
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

[![asciicast](https://asciinema.org/a/Kkh6H83kr1arR9DiqpmihStiQ.svg)](https://asciinema.org/a/Kkh6H83kr1arR9DiqpmihStiQ)

</details>

## Verify tom and laura have X-MY-KEY back

Verify tom and laura have X-MY-KEY back in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
    --property print.headers=true | jq
```


returns 2 events
```json
{
  "headers" : {
    "X-INTERPOLATED" : "User sa via ip 192.168.65.1",
    "X-MY-KEY" : "my own value",
    "X-USER" : "sa"
  },
  "value" : {
    "name" : "tom",
    "username" : "tom@conduktor.io",
    "password" : "motorhead",
    "visa" : "#abc123",
    "address" : "Chancery lane, London"
  }
}
{
  "headers" : {
    "X-INTERPOLATED" : "User sa via ip 192.168.65.1",
    "X-MY-KEY" : "my own value",
    "X-USER" : "sa"
  },
  "value" : {
    "name" : "laura",
    "username" : "laura@conduktor.io",
    "password" : "kitesurf",
    "visa" : "#888999XZ",
    "address" : "Dubai, UAE"
  }
}
```



</details>
<details>
<summary>Output</summary>

```json
jq: parse error: Invalid numeric literal at line 1, column 15
Processed a total of 2 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/0QZsGT0kYhsV5U821tyiL4diM.svg)](https://asciinema.org/a/0QZsGT0kYhsV5U821tyiL4diM)

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
 Container schema-registry  Stopping
 Container gateway1  Stopping
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka2  Stopping
 Container kafka1  Stopping
 Container kafka3  Stopping
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
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
 Network header-injection_default  Removing
 Network header-injection_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/3x2x8XjLPYZIZttMHr7EfbZCu.svg)](https://asciinema.org/a/3x2x8XjLPYZIZttMHr7EfbZCu)

</details>

# Conclusion

Leveraging headers in Kafka is of tremendous help!

