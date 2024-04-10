# Using Gateway ACL in your VClusters



## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/2Qbe9IXzXHu4LNWa6NolIO4ms.svg)](https://asciinema.org/a/2Qbe9IXzXHu4LNWa6NolIO4ms)

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
 Network acls-vcluster_default  Creating
 Network acls-vcluster_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka1  Creating
 Container kafka-client  Created
 Container kafka2  Creating
 Container kafka1  Created
 Container kafka3  Created
 Container kafka2  Created
 Container schema-registry  Creating
 Container gateway2  Creating
 Container gateway1  Creating
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
 Container zookeeper  Healthy
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container kafka2  Starting
 Container kafka3  Starting
 Container kafka1  Started
 Container kafka2  Started
 Container kafka3  Started
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container gateway2  Starting
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container gateway1  Starting
 Container gateway1  Started
 Container gateway2  Started
 Container schema-registry  Started
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container kafka1  Healthy
 Container kafka-client  Healthy
 Container kafka3  Healthy
 Container zookeeper  Healthy
 Container kafka2  Healthy
 Container schema-registry  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/qjN1FNOLPkUWDIkpAZxzmgiUa.svg)](https://asciinema.org/a/qjN1FNOLPkUWDIkpAZxzmgiUa)

</details>

## Creating virtual cluster aclCluster

Creating virtual cluster `aclCluster` on gateway `gateway1` and reviewing the configuration file to access it

<details>
<summary>Command</summary>



```sh
# Generate virtual cluster aclCluster with service account admin
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/aclCluster/username/admin" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

# Create access file
echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='admin' password='$token';
""" > aclCluster-admin.properties

# Review file
cat aclCluster-admin.properties
```



</details>
<details>
<summary>Output</summary>

```

bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='admin' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6ImFkbWluIiwidmNsdXN0ZXIiOiJhY2xDbHVzdGVyIiwiZXhwIjoxNzIwNDY4MDg1fQ.zRSsdDqs5_XwemsC3lN0L73qlQI4mmdy-jNOhZifhHc';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/utwIhyaVh9SxRG9o2fgl9Gjmw.svg)](https://asciinema.org/a/utwIhyaVh9SxRG9o2fgl9Gjmw)

</details>

## Creating virtual cluster aclCluster

Creating virtual cluster `aclCluster` on gateway `gateway1` and reviewing the configuration file to access it

<details>
<summary>Command</summary>



```sh
# Generate virtual cluster aclCluster with service account producer
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/aclCluster/username/producer" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

# Create access file
echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='producer' password='$token';
""" > aclCluster-producer.properties

# Review file
cat aclCluster-producer.properties
```



</details>
<details>
<summary>Output</summary>

```

bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='producer' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InByb2R1Y2VyIiwidmNsdXN0ZXIiOiJhY2xDbHVzdGVyIiwiZXhwIjoxNzIwNDY4MDg1fQ.b1qXJ6TSiDFhslfgULEVL443-OMH7Fa9D55TOb2E1Xk';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/drbPQCH5McVAjxrOf5h0gmCoZ.svg)](https://asciinema.org/a/drbPQCH5McVAjxrOf5h0gmCoZ)

</details>

## Creating virtual cluster aclCluster

Creating virtual cluster `aclCluster` on gateway `gateway1` and reviewing the configuration file to access it

<details>
<summary>Command</summary>



```sh
# Generate virtual cluster aclCluster with service account consumer
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/aclCluster/username/consumer" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

# Create access file
echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='consumer' password='$token';
""" > aclCluster-consumer.properties

# Review file
cat aclCluster-consumer.properties
```



</details>
<details>
<summary>Output</summary>

```

bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='consumer' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6ImNvbnN1bWVyIiwidmNsdXN0ZXIiOiJhY2xDbHVzdGVyIiwiZXhwIjoxNzIwNDY4MDg1fQ.nrn8-iIg6NVJ1geYR5yHt__b2r8xSlwy5qs0x7d7z7s';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/oMU5DDm4eCK6ZgUeBbdmVzHen.svg)](https://asciinema.org/a/oMU5DDm4eCK6ZgUeBbdmVzHen)

</details>

## Adding interceptor acl

Add ACL interceptor

Creating the interceptor named `acl` of the plugin `io.conduktor.gateway.interceptor.AclsInterceptorPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.AclsInterceptorPlugin",
  "priority" : 100,
  "config" : { }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-08-acl.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/aclCluster/interceptor/acl" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-acl.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.AclsInterceptorPlugin",
  "priority": 100,
  "config": {}
}
{
  "message": "acl is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/YI3BGHXaU8gIIswZzB3f6aoJj.svg)](https://asciinema.org/a/YI3BGHXaU8gIIswZzB3f6aoJj)

</details>

## Try to create a topic as a consumer

Creating on `aclCluster`:

* Topic `restricted-topic` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-consumer.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic restricted-topic
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> org.apache.kafka.common.errors.ClusterAuthorizationException:
>> Cluster not authorized
> ```





</details>
<details>
<summary>Output</summary>

```
Error while executing topic command : Cluster not authorized
[2024-04-09 23:48:06,885] ERROR org.apache.kafka.common.errors.ClusterAuthorizationException: Cluster not authorized
 (org.apache.kafka.tools.TopicCommand)

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/24HaHKBjCoUdhJqecksuVQ8C3.svg)](https://asciinema.org/a/24HaHKBjCoUdhJqecksuVQ8C3)

</details>

## Creating topic restricted-topic on aclCluster

Creating on `aclCluster`:

* Topic `restricted-topic` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-admin.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic restricted-topic
```



</details>
<details>
<summary>Output</summary>

```
Created topic restricted-topic.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/2Pqn3PL7XP4GRLugShU6vYJEi.svg)](https://asciinema.org/a/2Pqn3PL7XP4GRLugShU6vYJEi)

</details>

## List topics with consumer-sa does not throw error but gets no topic



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-consumer.properties \
    --list
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Gv5W8ExV6ntGXkHTtnV5GlLeC.svg)](https://asciinema.org/a/Gv5W8ExV6ntGXkHTtnV5GlLeC)

</details>

## Let's give read-access to test-topic for consumer SA



<details open>
<summary>Command</summary>



```sh
kafka-acls \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-admin.properties \
    --add \
    --allow-principal User:consumer \
    --operation read \
    --topic restricted-topic
```



</details>
<details>
<summary>Output</summary>

```
Adding ACLs for resource `ResourcePattern(resourceType=TOPIC, name=restricted-topic, patternType=LITERAL)`: 
 	(principal=User:consumer, host=*, operation=READ, permissionType=ALLOW) 

Current ACLs for resource `ResourcePattern(resourceType=TOPIC, name=restricted-topic, patternType=LITERAL)`: 
 	(principal=User:consumer, host=*, operation=READ, permissionType=ALLOW) 


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/QjfQkBpBYl6Bf6neLZfuPKNEE.svg)](https://asciinema.org/a/QjfQkBpBYl6Bf6neLZfuPKNEE)

</details>

## Consuming from _conduktor_gateway_acls

Consuming from _conduktor_gateway_acls in cluster `kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _conduktor_gateway_acls \
    --from-beginning \
    --timeout-ms 10000 \
    --property print.key=true | jq
```


returns 1 event
```json
{
  "key" : "{\"tenant\":\"aclCluster\",\"principal\":\"User:consumer\",\"host\":\"*\",\"resource\":{\"name\":\"restricted-topic\",\"resourceType\":\"TOPIC\",\"patternType\":\"LITERAL\"},\"operation\":\"READ\"}",
  "value" : true
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-09 23:48:23,927] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "tenant": "aclCluster",
  "principal": "User:consumer",
  "host": "*",
  "resource": {
    "name": "restricted-topic",
    "resourceType": "TOPIC",
    "patternType": "LITERAL"
  },
  "operation": "READ"
}
true

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/JpDyATqECyBNDwITNzQkGJvTA.svg)](https://asciinema.org/a/JpDyATqECyBNDwITNzQkGJvTA)

</details>

## Let's give read-access to fixed console-consumer for consumer SA



<details open>
<summary>Command</summary>



```sh
kafka-acls \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-admin.properties \
    --add \
    --allow-principal User:consumer \
    --operation read \
    --group console-consumer \
    --resource-pattern-type prefixed
```



</details>
<details>
<summary>Output</summary>

```
Adding ACLs for resource `ResourcePattern(resourceType=GROUP, name=console-consumer, patternType=PREFIXED)`: 
 	(principal=User:consumer, host=*, operation=READ, permissionType=ALLOW) 

Current ACLs for resource `ResourcePattern(resourceType=GROUP, name=console-consumer, patternType=PREFIXED)`: 
 	(principal=User:consumer, host=*, operation=READ, permissionType=ALLOW) 


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/mJyzUW5VxnjP8aOcRUiXUmbqI.svg)](https://asciinema.org/a/mJyzUW5VxnjP8aOcRUiXUmbqI)

</details>

## Listing topics in aclCluster



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-consumer.properties \
    --list
```



</details>
<details>
<summary>Output</summary>

```
restricted-topic

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/kZmEa0IdEQVHsHv1DZN3Lonkv.svg)](https://asciinema.org/a/kZmEa0IdEQVHsHv1DZN3Lonkv)

</details>

## Give read/write access to test-topic to producer SA



<details open>
<summary>Command</summary>



```sh
kafka-acls \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-admin.properties \
    --add \
    --allow-principal User:producer \
    --operation write \
    --topic restricted-topic 
```



</details>
<details>
<summary>Output</summary>

```
Adding ACLs for resource `ResourcePattern(resourceType=TOPIC, name=restricted-topic, patternType=LITERAL)`: 
 	(principal=User:producer, host=*, operation=WRITE, permissionType=ALLOW) 

Current ACLs for resource `ResourcePattern(resourceType=TOPIC, name=restricted-topic, patternType=LITERAL)`: 
 	(principal=User:producer, host=*, operation=WRITE, permissionType=ALLOW)
	(principal=User:consumer, host=*, operation=READ, permissionType=ALLOW) 


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/TJwmqJzNIDpkUDIgKtea7YpN4.svg)](https://asciinema.org/a/TJwmqJzNIDpkUDIgKtea7YpN4)

</details>

## Listing topics in aclCluster



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-producer.properties \
    --list
```



</details>
<details>
<summary>Output</summary>

```
restricted-topic

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/WuClDJRoESbKkVqPak07bXtGO.svg)](https://asciinema.org/a/WuClDJRoESbKkVqPak07bXtGO)

</details>

## Let's write into test-topic (producer)

Producing 1 message in `restricted-topic` in cluster `aclCluster`

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "msg" : "test message"
}
```
with


```sh
echo '{"msg":"test message"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config aclCluster-producer.properties \
        --topic restricted-topic
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/r6puqV0bJ65wg3PQ0SrEWYsq8.svg)](https://asciinema.org/a/r6puqV0bJ65wg3PQ0SrEWYsq8)

</details>

## Let's consume from test-topic (consumer)

Let's consume from test-topic (consumer) in cluster `aclCluster`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config aclCluster-consumer.properties \
    --topic restricted-topic \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 1 event
```json
{
  "msg" : "test message"
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-09 23:48:46,020] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "msg": "test message"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/PpQkT6TGSLyzu5JCz9hRv9nAY.svg)](https://asciinema.org/a/PpQkT6TGSLyzu5JCz9hRv9nAY)

</details>

## Consumer-sa cannot write into the test-topic

Producing 1 message in `restricted-topic` in cluster `aclCluster`

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "msg" : "I would be surprised if it would work!"
}
```
with


```sh
echo '{"msg":"I would be surprised if it would work!"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config aclCluster-consumer.properties \
        --topic restricted-topic
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> org.apache.kafka.common.errors.TopicAuthorizationException:
>> Not authorized to access topics: [restricted-topic]
> ```





</details>
<details>
<summary>Output</summary>

```
[2024-04-09 23:48:47,707] ERROR [Producer clientId=console-producer] Aborting producer batches due to fatal error (org.apache.kafka.clients.producer.internals.Sender)
org.apache.kafka.common.errors.TransactionalIdAuthorizationException: Transactional Id authorization failed.
[2024-04-09 23:48:47,708] ERROR Error when sending message to topic restricted-topic with key: null, value: 48 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.TransactionalIdAuthorizationException: Transactional Id authorization failed.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/EbB2rafo5mQUdZRFJjm7fAokf.svg)](https://asciinema.org/a/EbB2rafo5mQUdZRFJjm7fAokf)

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
 Container schema-registry  Stopping
 Container gateway1  Stopping
 Container gateway2  Stopping
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka1  Stopping
 Container kafka3  Stopping
 Container kafka2  Stopping
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
 Network acls-vcluster_default  Removing
 Network acls-vcluster_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/If6c4HQRTQkts1JJrMRuJVzJu.svg)](https://asciinema.org/a/If6c4HQRTQkts1JJrMRuJVzJu)

</details>

