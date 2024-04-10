# What is a safeguard?

Enforce your rules where it matters

Safeguard ensures that your teams follow your rules and can't break convention. 

Enable your teams, prevent common mistakes, protect your infra.

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/arD2teccUpSI9zRo30Q835pOh.svg)](https://asciinema.org/a/arD2teccUpSI9zRo30Q835pOh)

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
 Network safeguard_default  Creating
 Network safeguard_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container zookeeper  Created
 Container kafka-client  Created
 Container kafka3  Creating
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka3  Created
 Container kafka1  Created
 Container kafka2  Created
 Container schema-registry  Creating
 Container gateway2  Creating
 Container gateway1  Creating
 Container gateway1  Created
 Container gateway2  Created
 Container schema-registry  Created
 Container zookeeper  Starting
 Container kafka-client  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container kafka-client  Started
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container kafka1  Starting
 Container kafka3  Started
 Container kafka1  Started
 Container kafka2  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway2  Starting
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container gateway1  Started
 Container schema-registry  Started
 Container gateway2  Started
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container kafka3  Healthy
 Container kafka-client  Healthy
 Container kafka2  Healthy
 Container zookeeper  Healthy
 Container kafka1  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/gQuXseelhQ7btm1eCSOIlIIXZ.svg)](https://asciinema.org/a/gQuXseelhQ7btm1eCSOIlIIXZ)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ3OTQyOH0.NplDti0SEj4iAdXhugvkH0CBWYlqA_icLAFHnDRTo3M';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/XDGGIrtqwbLcycAvdjSZasbQa.svg)](https://asciinema.org/a/XDGGIrtqwbLcycAvdjSZasbQa)

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

[![asciicast](https://asciinema.org/a/ybq17SDpGwIXmPPWcqFDvEKQE.svg)](https://asciinema.org/a/ybq17SDpGwIXmPPWcqFDvEKQE)

</details>

## Producing 3 messages in cars

Produce 3 records to the cars topic.

<details>
<summary>Command</summary>



Sending 3 events
```json
{
  "type" : "Ferrari",
  "color" : "red",
  "price" : 10000
}
{
  "type" : "RollsRoyce",
  "color" : "black",
  "price" : 9000
}
{
  "type" : "Mercedes",
  "color" : "black",
  "price" : 6000
}
```
with


```sh
echo '{"type":"Ferrari","color":"red","price":10000}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars

echo '{"type":"RollsRoyce","color":"black","price":9000}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars

echo '{"type":"Mercedes","color":"black","price":6000}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
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

[![asciicast](https://asciinema.org/a/1f68nbj5hnei4Wv4XgCU9Lmxe.svg)](https://asciinema.org/a/1f68nbj5hnei4Wv4XgCU9Lmxe)

</details>

## Consume the cars topic

Let's confirm the 3 cars are there by consuming from the cars topic.

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 10000 | jq
```



</details>
<details>
<summary>Output</summary>

```json
Processed a total of 3 messages
{
  "type": "Ferrari",
  "color": "red",
  "price": 10000
}
{
  "type": "RollsRoyce",
  "color": "black",
  "price": 9000
}
{
  "type": "Mercedes",
  "color": "black",
  "price": 6000
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/9e54oIcbH2ienTCGv4oX3XRCe.svg)](https://asciinema.org/a/9e54oIcbH2ienTCGv4oX3XRCe)

</details>

## Describing topic cars

Replication factor is 1? 

This is bad: we can lose data!

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --describe \
    --topic cars
```



</details>
<details>
<summary>Output</summary>

```
Topic: cars	TopicId: bCvkKkk7TcGl88e25h53PA	PartitionCount: 1	ReplicationFactor: 1	Configs: 
	Topic: cars	Partition: 0	Leader: 2	Replicas: 2	Isr: 2

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/813ZB1qvuSFgNZ8m8BtBQEkOc.svg)](https://asciinema.org/a/813ZB1qvuSFgNZ8m8BtBQEkOc)

</details>

## Adding interceptor guard-on-create-topic

Let's make sure this problem never repeats itself and add a topic creation safeguard. 

... and while we're at it, let's make sure we don't abuse partitions either

Creating the interceptor named `guard-on-create-topic` of the plugin `io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin",
  "priority" : 100,
  "config" : {
    "replicationFactor" : {
      "min" : 2,
      "max" : 2
    },
    "numPartition" : {
      "min" : 1,
      "max" : 3
    }
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-10-guard-on-create-topic.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-10-guard-on-create-topic.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin",
  "priority": 100,
  "config": {
    "replicationFactor": {
      "min": 2,
      "max": 2
    },
    "numPartition": {
      "min": 1,
      "max": 3
    }
  }
}
{
  "message": "guard-on-create-topic is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/XetiViIFRWs0LlNDzI545hy0U.svg)](https://asciinema.org/a/XetiViIFRWs0LlNDzI545hy0U)

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
      "name": "guard-on-create-topic",
      "pluginClass": "io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "replicationFactor": {
          "min": 2,
          "max": 2
        },
        "numPartition": {
          "min": 1,
          "max": 3
        }
      }
    }
  ]
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/8DL6hYbUG1dRV2U3cVxU5hq8K.svg)](https://asciinema.org/a/8DL6hYbUG1dRV2U3cVxU5hq8K)

</details>

## Create a topic that is not within policy

Topic creation is denied by our policy

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 100 \
    --create --if-not-exists \
    --topic roads
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> org.apache.kafka.common.errors.PolicyViolationException:
>> Request parameters do not satisfy the configured policy.
>>Topic 'roads' with number partitions is '100', must not be greater than 3.
>>Topic 'roads' with replication factor is '1', must not be less than 2
> ```





</details>
<details>
<summary>Output</summary>

```
Error while executing topic command : Request parameters do not satisfy the configured policy. Topic 'roads' with number partitions is '100', must not be greater than 3. Topic 'roads' with replication factor is '1', must not be less than 2
[2024-04-10 02:57:19,271] ERROR org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Topic 'roads' with number partitions is '100', must not be greater than 3. Topic 'roads' with replication factor is '1', must not be less than 2
 (org.apache.kafka.tools.TopicCommand)

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/UOUqJ64ZxlnkL0ziYKhXilLLG.svg)](https://asciinema.org/a/UOUqJ64ZxlnkL0ziYKhXilLLG)

</details>

## Let's now create it again, with parameters within our policy

Perfect, it has been created

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 2 \
    --partitions 3 \
    --create --if-not-exists \
    --topic roads
```



</details>
<details>
<summary>Output</summary>

```
Created topic roads.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/JIW2xGyjWBm60w3CQegRYgJ1Y.svg)](https://asciinema.org/a/JIW2xGyjWBm60w3CQegRYgJ1Y)

</details>

## Adding interceptor guard-on-alter-topic

Let's make sure we enforce policies when we alter topics too

Here the retention can only be between 1 and 5 days

Creating the interceptor named `guard-on-alter-topic` of the plugin `io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin",
  "priority" : 100,
  "config" : {
    "retentionMs" : {
      "min" : 86400000,
      "max" : 432000000
    }
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-14-guard-on-alter-topic.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-alter-topic" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-14-guard-on-alter-topic.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin",
  "priority": 100,
  "config": {
    "retentionMs": {
      "min": 86400000,
      "max": 432000000
    }
  }
}
{
  "message": "guard-on-alter-topic is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/m3I7sWjldEkXxttTYekawx5yL.svg)](https://asciinema.org/a/m3I7sWjldEkXxttTYekawx5yL)

</details>

## Update 'cars' with a retention of 60 days

Altering the topic is denied by our policy

<details open>
<summary>Command</summary>



```sh
kafka-configs \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --alter \
    --entity-type topics \
    --entity-name roads \
    --add-config retention.ms=5184000000
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> org.apache.kafka.common.errors.PolicyViolationException:
>> Request parameters do not satisfy the configured policy. Resource 'roads' with retention.ms is '5184000000', must not be greater than '432000000'
> ```





</details>
<details>
<summary>Output</summary>

```
Error while executing config command with args '--bootstrap-server localhost:6969 --command-config teamA-sa.properties --alter --entity-type topics --entity-name roads --add-config retention.ms=5184000000'
java.util.concurrent.ExecutionException: org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Resource 'roads' with retention.ms is '5184000000', must not be greater than '432000000'
	at java.base/java.util.concurrent.CompletableFuture.reportGet(CompletableFuture.java:396)
	at java.base/java.util.concurrent.CompletableFuture.get(CompletableFuture.java:2096)
	at org.apache.kafka.common.internals.KafkaFutureImpl.get(KafkaFutureImpl.java:180)
	at kafka.admin.ConfigCommand$.alterConfig(ConfigCommand.scala:374)
	at kafka.admin.ConfigCommand$.processCommand(ConfigCommand.scala:341)
	at kafka.admin.ConfigCommand$.main(ConfigCommand.scala:97)
	at kafka.admin.ConfigCommand.main(ConfigCommand.scala)
Caused by: org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Resource 'roads' with retention.ms is '5184000000', must not be greater than '432000000'

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/1PlXWcTl122vf0w4hItTNYcOA.svg)](https://asciinema.org/a/1PlXWcTl122vf0w4hItTNYcOA)

</details>

## Update 'cars' with a retention of 3 days

Topic updated successfully

<details open>
<summary>Command</summary>



```sh
kafka-configs \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --alter \
    --entity-type topics \
    --entity-name roads \
    --add-config retention.ms=259200000
```



</details>
<details>
<summary>Output</summary>

```
Completed updating config for topic roads.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/sHpX8r6PyWxP5i6kok3m8YqE5.svg)](https://asciinema.org/a/sHpX8r6PyWxP5i6kok3m8YqE5)

</details>

## Adding interceptor guard-on-produce

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

<details open>
<summary>Command</summary>



```sh
cat step-17-guard-on-produce.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-produce" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-17-guard-on-produce.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
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
{
  "message": "guard-on-produce is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/GCzetDq70TVcwjtTKtd6AEGQT.svg)](https://asciinema.org/a/GCzetDq70TVcwjtTKtd6AEGQT)

</details>

## Produce sample data to our cars topic without the right policies

Produce 1 record ... that do not match our policy

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "type" : "Fiat",
  "color" : "red",
  "price" : -1
}
```
with


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





</details>
<details>
<summary>Output</summary>

```
[2024-04-10 02:57:25,872] ERROR Error when sending message to topic cars with key: null, value: 40 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1. Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/IKDvlejJDG5t1pMUcBxkpZMYg.svg)](https://asciinema.org/a/IKDvlejJDG5t1pMUcBxkpZMYg)

</details>

## Produce sample data to our cars topic that complies with our policy

Producing a record matching our policy

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "type" : "Fiat",
  "color" : "red",
  "price" : -1
}
```
with


```sh
echo '{"type":"Fiat","color":"red","price":-1}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --request-required-acks -1 \
        --compression-codec gzip \
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

[![asciicast](https://asciinema.org/a/avlYU4UFsAwkynQryMm39ef7a.svg)](https://asciinema.org/a/avlYU4UFsAwkynQryMm39ef7a)

</details>

## Adding interceptor produce-rate

Let's add some rate limiting policy on produce

Creating the interceptor named `produce-rate` of the plugin `io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin",
  "priority" : 100,
  "config" : {
    "maximumBytesPerSecond" : 1
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-20-produce-rate.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-20-produce-rate.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin",
  "priority": 100,
  "config": {
    "maximumBytesPerSecond": 1
  }
}
{
  "message": "produce-rate is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/fTd4SlfXNdfZrHgCxpTCTRkjq.svg)](https://asciinema.org/a/fTd4SlfXNdfZrHgCxpTCTRkjq)

</details>

## Produce sample data

Do not match our produce rate policy

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "type" : "Fiat",
  "color" : "red",
  "price" : -1
}
```
with


```sh
echo '{"type":"Fiat","color":"red","price":-1}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --request-required-acks -1 \
        --compression-codec none \
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

[![asciicast](https://asciinema.org/a/ESM97sH0gDgr17a3Duh8yJPh8.svg)](https://asciinema.org/a/ESM97sH0gDgr17a3Duh8yJPh8)

</details>

## Check in the audit log that produce was throttled

Check in the audit log that produce was throttled in cluster `kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _conduktor_gateway_auditlogs \
    --from-beginning \
    --timeout-ms 3000 \| jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin")'
```


returns 1 event
```json
{
  "id" : "bb3743f3-3b0a-4295-abe6-0606c5164463",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:16536"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:35.507223211Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin",
    "message" : "Client produced (108) bytes, which is more than 1 bytes per second, producer will be throttled by 969 milliseconds"
  }
}
```



</details>
<details>
<summary>Output</summary>

```
{"id":"ad5d2cbf-2bd1-4dce-8d29-1c42939922e1","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28491"},"specVersion":"0.1.0","time":"2024-04-09T22:57:08.780478796Z","eventData":{"method":"POST","path":"/admin/vclusters/v1/vcluster/teamA/username/sa","body":"{\"lifeTimeSeconds\": 7776000}"}}
{"id":"7419d31b-b9ac-468b-bc30-b0d6d29837ce","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17069"},"specVersion":"0.1.0","time":"2024-04-09T22:57:09.742668879Z","eventData":"SUCCESS"}
{"id":"4263b2d4-ad38-4d7e-a4c0-59d9f6521456","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32960"},"specVersion":"0.1.0","time":"2024-04-09T22:57:09.827216255Z","eventData":"SUCCESS"}
{"id":"b9574b20-5776-4e71-a362-e18556218757","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17071"},"specVersion":"0.1.0","time":"2024-04-09T22:57:11.336087922Z","eventData":"SUCCESS"}
{"id":"ca2f053b-c936-4a7f-92f2-4b21f62d2252","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32962"},"specVersion":"0.1.0","time":"2024-04-09T22:57:11.373917880Z","eventData":"SUCCESS"}
{"id":"ab746ef4-9793-4b29-81df-0e7fae1538d3","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17073"},"specVersion":"0.1.0","time":"2024-04-09T22:57:12.764087214Z","eventData":"SUCCESS"}
{"id":"60dcba90-1cf1-4018-a9a7-19b3eec5ed55","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32964"},"specVersion":"0.1.0","time":"2024-04-09T22:57:12.796650298Z","eventData":"SUCCESS"}
{"id":"eb2d20fb-24de-44d4-bdf2-033ba9e8e281","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17075"},"specVersion":"0.1.0","time":"2024-04-09T22:57:14.123940465Z","eventData":"SUCCESS"}
{"id":"21b4840a-af5d-4785-a79e-a4fddd4acd3b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32966"},"specVersion":"0.1.0","time":"2024-04-09T22:57:14.158265590Z","eventData":"SUCCESS"}
{"id":"e88a3bcf-1bdb-4a79-aebd-7afc09064716","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17077"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.534253132Z","eventData":"SUCCESS"}
{"id":"c0178ae2-dd59-45de-a835-74161eb10843","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32968"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.565131466Z","eventData":"SUCCESS"}
{"id":"451b2171-737d-4506-a0f7-2c4ac6e78f53","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32969"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.693036716Z","eventData":"SUCCESS"}
{"id":"34f347bf-e604-4f18-b2e0-ee2968086384","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17092"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.579152217Z","eventData":"SUCCESS"}
{"id":"d02d0408-fac0-42eb-8be4-f0649aedffb2","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32983"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.597597925Z","eventData":"SUCCESS"}
{"id":"08438b0d-c1f1-4fa4-afdc-1843f88fbcf8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17094"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.624725050Z","eventData":"SUCCESS"}
{"id":"cdc7a87b-9fe1-4016-8e46-7a45ccd66d46","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28530"},"specVersion":"0.1.0","time":"2024-04-09T22:57:18.119768675Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"replicationFactor\" : {      \"min\" : 2,      \"max\" : 2    },    \"numPartition\" : {      \"min\" : 1,      \"max\" : 3    }  }}"}}
{"id":"2cc00de7-bb9d-4c28-b305-135de9138061","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28531"},"specVersion":"0.1.0","time":"2024-04-09T22:57:18.318868092Z","eventData":{"method":"GET","path":"/admin/interceptors/v1/vcluster/teamA","body":null}}
{"id":"63b9ef30-2fd7-4db1-9d16-7610cfdf9272","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17109"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.217374842Z","eventData":"SUCCESS"}
{"id":"36de93e8-b1a6-47ff-bacf-d79a3b89b717","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33000"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.238897509Z","eventData":"SUCCESS"}
{"id":"35607bf6-05ea-4f83-b87a-2e9130f21fcc","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33000"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.258906592Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin","message":"Request parameters do not satisfy the configured policy. Topic 'roads' with number partitions is '100', must not be greater than 3. Topic 'roads' with replication factor is '1', must not be less than 2"}}
{"id":"bc94cc84-51f9-4dca-b918-9d09fe18fffd","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17111"},"specVersion":"0.1.0","time":"2024-04-09T22:57:20.582032760Z","eventData":"SUCCESS"}
{"id":"1f2a13e1-79d8-4741-a7cf-663b8c69a1a9","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33002"},"specVersion":"0.1.0","time":"2024-04-09T22:57:20.603914426Z","eventData":"SUCCESS"}
{"id":"13aa671a-eba1-4822-8b4a-790b19e6f517","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28536"},"specVersion":"0.1.0","time":"2024-04-09T22:57:21.149915843Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-alter-topic","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"retentionMs\" : {      \"min\" : 86400000,      \"max\" : 432000000    }  }}"}}
{"id":"0322d61d-f26b-4897-b190-ef31faeb144a","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17114"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.234666177Z","eventData":"SUCCESS"}
{"id":"12a03f8c-eb46-4297-ac05-c0d43f7c6a45","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6971","remoteAddress":"/192.168.65.1:44385"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.258857260Z","eventData":"SUCCESS"}
{"id":"ac9d937d-daa7-482a-95e8-7e21c55ff51e","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:44385"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.322798385Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin","message":"Request parameters do not satisfy the configured policy. Resource 'roads' with retention.ms is '5184000000', must not be greater than '432000000'"}}
{"id":"1c5884ec-6ea6-4974-846e-0fc3a1881bb8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17116"},"specVersion":"0.1.0","time":"2024-04-09T22:57:23.728982886Z","eventData":"SUCCESS"}
{"id":"3854b5d0-bb85-4735-be81-0597237ad8b1","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33007"},"specVersion":"0.1.0","time":"2024-04-09T22:57:23.748231761Z","eventData":"SUCCESS"}
{"id":"fee03330-e546-4297-bf83-8038a2f0ed55","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28541"},"specVersion":"0.1.0","time":"2024-04-09T22:57:24.302672303Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-produce","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"acks\" : {      \"value\" : [ -1 ],      \"action\" : \"BLOCK\"    },    \"compressions\" : {      \"value\" : [ \"NONE\", \"GZIP\" ],      \"action\" : \"BLOCK\"    }  }}"}}
{"id":"930007bb-3325-45f7-875e-b374ebc54548","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17119"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.298030595Z","eventData":"SUCCESS"}
{"id":"164bdf3d-d1b8-4849-9188-5ef823d8cd0b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33010"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.813463304Z","eventData":"SUCCESS"}
{"id":"b18e0515-feb4-45d8-aadc-50bc76a75c5d","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33010"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.864088137Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin","message":"Request parameters do not satisfy the configured policy. Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1. Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]"}}
{"id":"2d45242b-ea94-43d1-8055-c4972f6b8481","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17121"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.192247179Z","eventData":"SUCCESS"}
{"id":"c49ce88e-8f18-48c4-bf71-66f11607c03e","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33012"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.220203596Z","eventData":"SUCCESS"}
{"id":"b7710805-24c4-4c2a-a4ab-53701928a435","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28558"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.680550388Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"maximumBytesPerSecond\" : 1  }}"}}
{"id":"4659321f-3f7f-4564-a5aa-e8179a0682b7","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17148"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.620101472Z","eventData":"SUCCESS"}
{"id":"78366d0c-a400-4365-9f7d-41e3c7030bb3","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33039"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.648120222Z","eventData":"SUCCESS"}
{"id":"1cf909c0-2610-412c-b257-15a5af81b682","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33039"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.662161305Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin","message":"Client produced (108) bytes, which is more than 1 bytes per second, producer will be throttled by 44 milliseconds"}}
[2024-04-10 02:57:33,143] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 38 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Ne68ohQitbX7Ja8g8mvjYWbvA.svg)](https://asciinema.org/a/Ne68ohQitbX7Ja8g8mvjYWbvA)

</details>

## Remove interceptor produce-rate



<details open>
<summary>Command</summary>



```sh
curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate" \
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

[![asciicast](https://asciinema.org/a/Ae9Hp63rVbicsertPoy0smzVW.svg)](https://asciinema.org/a/Ae9Hp63rVbicsertPoy0smzVW)

</details>

## Adding interceptor consumer-group-name-policy

Let's add some naming conventions on consumer group names

Creating the interceptor named `consumer-group-name-policy` of the plugin `io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin",
  "priority" : 100,
  "config" : {
    "groupId" : {
      "value" : "my-group.*",
      "action" : "BLOCK"
    }
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-24-consumer-group-name-policy.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-24-consumer-group-name-policy.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin",
  "priority": 100,
  "config": {
    "groupId": {
      "value": "my-group.*",
      "action": "BLOCK"
    }
  }
}
{
  "message": "consumer-group-name-policy is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Vb3IUoCQoXUoaDxOXAkkQ6zj4.svg)](https://asciinema.org/a/Vb3IUoCQoXUoaDxOXAkkQ6zj4)

</details>

## Consuming from cars

Consuming from cars in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group group-not-within-policy | jq
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> Unexpected error in join group response: Request parameters do not satisfy the configured policy.
> ```





</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 02:57:34,753] ERROR [Consumer clientId=console-consumer, groupId=group-not-within-policy] JoinGroup failed due to unexpected error: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-04-10 02:57:34,754] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.KafkaException: Unexpected error in join group response: Request parameters do not satisfy the configured policy.
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$JoinGroupResponseHandler.handle(AbstractCoordinator.java:741)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$JoinGroupResponseHandler.handle(AbstractCoordinator.java:631)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$CoordinatorResponseHandler.onSuccess(AbstractCoordinator.java:1300)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$CoordinatorResponseHandler.onSuccess(AbstractCoordinator.java:1275)
	at org.apache.kafka.clients.consumer.internals.RequestFuture$1.onSuccess(RequestFuture.java:206)
	at org.apache.kafka.clients.consumer.internals.RequestFuture.fireSuccess(RequestFuture.java:169)
	at org.apache.kafka.clients.consumer.internals.RequestFuture.complete(RequestFuture.java:129)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient$RequestFutureCompletionHandler.fireCompletion(ConsumerNetworkClient.java:616)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.firePendingCompletedRequests(ConsumerNetworkClient.java:428)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:313)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:252)
	at org.apache.kafka.clients.consumer.internals.LegacyKafkaConsumer.pollForFetches(LegacyKafkaConsumer.java:686)
	at org.apache.kafka.clients.consumer.internals.LegacyKafkaConsumer.poll(LegacyKafkaConsumer.java:617)
	at org.apache.kafka.clients.consumer.internals.LegacyKafkaConsumer.poll(LegacyKafkaConsumer.java:590)
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:874)
	at kafka.tools.ConsoleConsumer$ConsumerWrapper.receive(ConsoleConsumer.scala:473)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:103)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:77)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:54)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Processed a total of 0 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/kusW9g5Nsc8GnAXOKCZVeXO2t.svg)](https://asciinema.org/a/kusW9g5Nsc8GnAXOKCZVeXO2t)

</details>

## Check in the audit log that fetch was denied

Check in the audit log that fetch was denied in cluster `kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _conduktor_gateway_auditlogs \
    --from-beginning \
    --timeout-ms 3000 \| jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin")'
```


returns 1 event
```json
{
  "id" : "5f8a5b25-49f6-4bd3-8999-42ef84051101",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:43837"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:38.805738754Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin",
    "message" : "Request parameters do not satisfy the configured policy. GroupId 'group-not-within-policy' is invalid, naming convention must match with regular expression my-group.*"
  }
}
```



</details>
<details>
<summary>Output</summary>

```
{"id":"ad5d2cbf-2bd1-4dce-8d29-1c42939922e1","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28491"},"specVersion":"0.1.0","time":"2024-04-09T22:57:08.780478796Z","eventData":{"method":"POST","path":"/admin/vclusters/v1/vcluster/teamA/username/sa","body":"{\"lifeTimeSeconds\": 7776000}"}}
{"id":"7419d31b-b9ac-468b-bc30-b0d6d29837ce","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17069"},"specVersion":"0.1.0","time":"2024-04-09T22:57:09.742668879Z","eventData":"SUCCESS"}
{"id":"4263b2d4-ad38-4d7e-a4c0-59d9f6521456","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32960"},"specVersion":"0.1.0","time":"2024-04-09T22:57:09.827216255Z","eventData":"SUCCESS"}
{"id":"b9574b20-5776-4e71-a362-e18556218757","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17071"},"specVersion":"0.1.0","time":"2024-04-09T22:57:11.336087922Z","eventData":"SUCCESS"}
{"id":"ca2f053b-c936-4a7f-92f2-4b21f62d2252","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32962"},"specVersion":"0.1.0","time":"2024-04-09T22:57:11.373917880Z","eventData":"SUCCESS"}
{"id":"ab746ef4-9793-4b29-81df-0e7fae1538d3","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17073"},"specVersion":"0.1.0","time":"2024-04-09T22:57:12.764087214Z","eventData":"SUCCESS"}
{"id":"60dcba90-1cf1-4018-a9a7-19b3eec5ed55","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32964"},"specVersion":"0.1.0","time":"2024-04-09T22:57:12.796650298Z","eventData":"SUCCESS"}
{"id":"eb2d20fb-24de-44d4-bdf2-033ba9e8e281","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17075"},"specVersion":"0.1.0","time":"2024-04-09T22:57:14.123940465Z","eventData":"SUCCESS"}
{"id":"21b4840a-af5d-4785-a79e-a4fddd4acd3b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32966"},"specVersion":"0.1.0","time":"2024-04-09T22:57:14.158265590Z","eventData":"SUCCESS"}
{"id":"e88a3bcf-1bdb-4a79-aebd-7afc09064716","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17077"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.534253132Z","eventData":"SUCCESS"}
{"id":"c0178ae2-dd59-45de-a835-74161eb10843","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32968"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.565131466Z","eventData":"SUCCESS"}
{"id":"451b2171-737d-4506-a0f7-2c4ac6e78f53","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32969"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.693036716Z","eventData":"SUCCESS"}
{"id":"34f347bf-e604-4f18-b2e0-ee2968086384","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17092"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.579152217Z","eventData":"SUCCESS"}
{"id":"d02d0408-fac0-42eb-8be4-f0649aedffb2","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32983"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.597597925Z","eventData":"SUCCESS"}
{"id":"08438b0d-c1f1-4fa4-afdc-1843f88fbcf8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17094"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.624725050Z","eventData":"SUCCESS"}
{"id":"cdc7a87b-9fe1-4016-8e46-7a45ccd66d46","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28530"},"specVersion":"0.1.0","time":"2024-04-09T22:57:18.119768675Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"replicationFactor\" : {      \"min\" : 2,      \"max\" : 2    },    \"numPartition\" : {      \"min\" : 1,      \"max\" : 3    }  }}"}}
{"id":"2cc00de7-bb9d-4c28-b305-135de9138061","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28531"},"specVersion":"0.1.0","time":"2024-04-09T22:57:18.318868092Z","eventData":{"method":"GET","path":"/admin/interceptors/v1/vcluster/teamA","body":null}}
{"id":"63b9ef30-2fd7-4db1-9d16-7610cfdf9272","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17109"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.217374842Z","eventData":"SUCCESS"}
{"id":"36de93e8-b1a6-47ff-bacf-d79a3b89b717","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33000"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.238897509Z","eventData":"SUCCESS"}
{"id":"35607bf6-05ea-4f83-b87a-2e9130f21fcc","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33000"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.258906592Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin","message":"Request parameters do not satisfy the configured policy. Topic 'roads' with number partitions is '100', must not be greater than 3. Topic 'roads' with replication factor is '1', must not be less than 2"}}
{"id":"bc94cc84-51f9-4dca-b918-9d09fe18fffd","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17111"},"specVersion":"0.1.0","time":"2024-04-09T22:57:20.582032760Z","eventData":"SUCCESS"}
{"id":"1f2a13e1-79d8-4741-a7cf-663b8c69a1a9","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33002"},"specVersion":"0.1.0","time":"2024-04-09T22:57:20.603914426Z","eventData":"SUCCESS"}
{"id":"13aa671a-eba1-4822-8b4a-790b19e6f517","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28536"},"specVersion":"0.1.0","time":"2024-04-09T22:57:21.149915843Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-alter-topic","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"retentionMs\" : {      \"min\" : 86400000,      \"max\" : 432000000    }  }}"}}
{"id":"0322d61d-f26b-4897-b190-ef31faeb144a","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17114"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.234666177Z","eventData":"SUCCESS"}
{"id":"12a03f8c-eb46-4297-ac05-c0d43f7c6a45","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6971","remoteAddress":"/192.168.65.1:44385"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.258857260Z","eventData":"SUCCESS"}
{"id":"ac9d937d-daa7-482a-95e8-7e21c55ff51e","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:44385"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.322798385Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin","message":"Request parameters do not satisfy the configured policy. Resource 'roads' with retention.ms is '5184000000', must not be greater than '432000000'"}}
{"id":"1c5884ec-6ea6-4974-846e-0fc3a1881bb8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17116"},"specVersion":"0.1.0","time":"2024-04-09T22:57:23.728982886Z","eventData":"SUCCESS"}
{"id":"3854b5d0-bb85-4735-be81-0597237ad8b1","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33007"},"specVersion":"0.1.0","time":"2024-04-09T22:57:23.748231761Z","eventData":"SUCCESS"}
{"id":"fee03330-e546-4297-bf83-8038a2f0ed55","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28541"},"specVersion":"0.1.0","time":"2024-04-09T22:57:24.302672303Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-produce","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"acks\" : {      \"value\" : [ -1 ],      \"action\" : \"BLOCK\"    },    \"compressions\" : {      \"value\" : [ \"NONE\", \"GZIP\" ],      \"action\" : \"BLOCK\"    }  }}"}}
{"id":"930007bb-3325-45f7-875e-b374ebc54548","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17119"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.298030595Z","eventData":"SUCCESS"}
{"id":"164bdf3d-d1b8-4849-9188-5ef823d8cd0b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33010"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.813463304Z","eventData":"SUCCESS"}
{"id":"b18e0515-feb4-45d8-aadc-50bc76a75c5d","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33010"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.864088137Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin","message":"Request parameters do not satisfy the configured policy. Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1. Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]"}}
{"id":"2d45242b-ea94-43d1-8055-c4972f6b8481","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17121"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.192247179Z","eventData":"SUCCESS"}
{"id":"c49ce88e-8f18-48c4-bf71-66f11607c03e","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33012"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.220203596Z","eventData":"SUCCESS"}
{"id":"b7710805-24c4-4c2a-a4ab-53701928a435","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28558"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.680550388Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"maximumBytesPerSecond\" : 1  }}"}}
{"id":"4659321f-3f7f-4564-a5aa-e8179a0682b7","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17148"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.620101472Z","eventData":"SUCCESS"}
{"id":"78366d0c-a400-4365-9f7d-41e3c7030bb3","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33039"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.648120222Z","eventData":"SUCCESS"}
{"id":"1cf909c0-2610-412c-b257-15a5af81b682","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33039"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.662161305Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin","message":"Client produced (108) bytes, which is more than 1 bytes per second, producer will be throttled by 44 milliseconds"}}
{"id":"f310f6a4-54ab-46fd-b956-9177bdde8416","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28577"},"specVersion":"0.1.0","time":"2024-04-09T22:57:33.671817502Z","eventData":{"method":"DELETE","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate","body":null}}
{"id":"17f183eb-56c6-4d0b-bc4f-e7b01f0d9ee1","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28578"},"specVersion":"0.1.0","time":"2024-04-09T22:57:33.726142043Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"groupId\" : {      \"value\" : \"my-group.*\",      \"action\" : \"BLOCK\"    }  }}"}}
{"id":"c2092f02-6d9d-447d-912c-07a3d9fdd04d","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17156"},"specVersion":"0.1.0","time":"2024-04-09T22:57:34.717949919Z","eventData":"SUCCESS"}
{"id":"8b2f1ed7-4d7b-426a-a105-d3961ae8c6a0","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6971","remoteAddress":"/192.168.65.1:44427"},"specVersion":"0.1.0","time":"2024-04-09T22:57:34.745343752Z","eventData":"SUCCESS"}
{"id":"cac027b2-a847-48b2-be7a-0abc76d70e2a","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:44427"},"specVersion":"0.1.0","time":"2024-04-09T22:57:34.751896794Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin","message":"Request parameters do not satisfy the configured policy. GroupId 'group-not-within-policy' is invalid, naming convention must match with regular expression my-group.*"}}
[2024-04-10 02:57:39,203] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 43 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/RPFbG7XhlT1ZiTwCntBW4oFYm.svg)](https://asciinema.org/a/RPFbG7XhlT1ZiTwCntBW4oFYm)

</details>

## Consuming from cars

Consuming from cars in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group my-group-within-policy | jq
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 02:57:50,788] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 5 messages
{
  "type": "Ferrari",
  "color": "red",
  "price": 10000
}
{
  "type": "RollsRoyce",
  "color": "black",
  "price": 9000
}
{
  "type": "Mercedes",
  "color": "black",
  "price": 6000
}
{
  "type": "Fiat",
  "color": "red",
  "price": -1
}
{
  "type": "Fiat",
  "color": "red",
  "price": -1
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/RllC4uk2neps9MnJ3zEMGtK7g.svg)](https://asciinema.org/a/RllC4uk2neps9MnJ3zEMGtK7g)

</details>

## Remove interceptor consumer-group-name-policy



<details open>
<summary>Command</summary>



```sh
curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy" \
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

[![asciicast](https://asciinema.org/a/zYy0SS8HBFZoBO10P9BWBz2qx.svg)](https://asciinema.org/a/zYy0SS8HBFZoBO10P9BWBz2qx)

</details>

## Adding interceptor guard-limit-connection

Let's add some connect limitation policy

Creating the interceptor named `guard-limit-connection` of the plugin `io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
  "priority" : 100,
  "config" : {
    "maximumConnectionsPerSecond" : 1,
    "action" : "BLOCK"
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-29-guard-limit-connection.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-29-guard-limit-connection.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
  "priority": 100,
  "config": {
    "maximumConnectionsPerSecond": 1,
    "action": "BLOCK"
  }
}
{
  "message": "guard-limit-connection is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/rKWWnsadARkUXiCV4t8YXrNPl.svg)](https://asciinema.org/a/rKWWnsadARkUXiCV4t8YXrNPl)

</details>

## Consuming from cars

Consuming from cars in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group my-group-id-convention-cars | jq
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> Request parameters do not satisfy the configured policy.
> ```





</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 02:57:53,161] WARN [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] Received error POLICY_VIOLATION from node 2147483646 when making an ApiVersionsRequest with correlation id 5. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 02:57:53,968] WARN [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] Received error POLICY_VIOLATION from node 1 when making an ApiVersionsRequest with correlation id 7. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 02:57:55,044] WARN [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] Received error POLICY_VIOLATION from node 2147483646 when making an ApiVersionsRequest with correlation id 12. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 02:57:55,294] WARN [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] Received error POLICY_VIOLATION from node 2147483646 when making an ApiVersionsRequest with correlation id 17. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 02:58:05,816] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
[2024-04-10 02:58:06,351] ERROR [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] Offset commit failed on partition cars-0 at offset 5: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-04-10 02:58:06,353] ERROR [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] Offset commit failed on partition cars-0 at offset 5: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-04-10 02:58:06,353] WARN [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] Asynchronous auto-commit of offsets {cars-0=OffsetAndMetadata{offset=5, leaderEpoch=0, metadata=''}} failed: Unexpected error in commit: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-04-10 02:58:06,353] WARN [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] Synchronous auto-commit of offsets {cars-0=OffsetAndMetadata{offset=5, leaderEpoch=0, metadata=''}} failed: Unexpected error in commit: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-04-10 02:58:07,382] ERROR [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] LeaveGroup request with Generation{generationId=1, memberId='console-consumer-bc446a2d-8fad-42a6-a2fe-d3d50fcb23bc', protocol='range'} failed with error: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
Processed a total of 5 messages
{
  "type": "Ferrari",
  "color": "red",
  "price": 10000
}
{
  "type": "RollsRoyce",
  "color": "black",
  "price": 9000
}
{
  "type": "Mercedes",
  "color": "black",
  "price": 6000
}
{
  "type": "Fiat",
  "color": "red",
  "price": -1
}
{
  "type": "Fiat",
  "color": "red",
  "price": -1
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/iscwxper6Tpsmz9XmTrsbDJK6.svg)](https://asciinema.org/a/iscwxper6Tpsmz9XmTrsbDJK6)

</details>

## Check in the audit log that connection was denied

Check in the audit log that connection was denied in cluster `kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _conduktor_gateway_auditlogs \
    --from-beginning \
    --timeout-ms 3000 \| jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin")'
```


returns 15 events
```json
{
  "id" : "b8d4a746-bc68-478d-8394-7812a6399846",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:16601"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:52.513955969Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "19f9e2ed-5530-4abe-8d30-51ee370b91ae",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:16524"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:52.641155511Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "282791d0-a80f-4cb4-b54f-64b50d8fd464",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:16602"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:52.868845011Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "ca52f0a6-1e23-4140-9d82-0fd7c8c30cff",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:16524"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:52.991739219Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "9e865a4c-55c2-436a-934c-7e1390d87f92",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:32493"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:53.159412928Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "55ad6533-862b-4377-9dc9-74122924f314",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:43874"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:54.024294595Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "280dfff8-54d8-4c7c-935d-42ac1e480ac4",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:32462"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:54.551201595Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "1d68a2e7-7b49-41e6-b136-131f3bccf75c",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:16606"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:54.641131720Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "7aea66fc-1d34-4e5f-b66e-600bd9844879",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:32462"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:55.118344470Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "cca8ba40-03e4-4eb5-a224-9ea946de8b34",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:16607"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:55.247603970Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "c6884272-c8b4-4bcc-9e33-c49d2d7384c1",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:32462"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:55.841341512Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "c4814506-eee9-46f1-b126-f2931c6f5234",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:16608"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:56.105952804Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "4640f9e1-e4a9-4831-b744-249cb12d15b2",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:32462"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:56.516627596Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "1fc48081-c301-4e66-aeb2-27ae71065285",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:16605"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:57.271249055Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "0863dfe0-7aec-4592-a42b-ab8cc953ab8b",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:32462"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:55:57.678578513Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
```



</details>
<details>
<summary>Output</summary>

```
{"id":"ad5d2cbf-2bd1-4dce-8d29-1c42939922e1","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28491"},"specVersion":"0.1.0","time":"2024-04-09T22:57:08.780478796Z","eventData":{"method":"POST","path":"/admin/vclusters/v1/vcluster/teamA/username/sa","body":"{\"lifeTimeSeconds\": 7776000}"}}
{"id":"7419d31b-b9ac-468b-bc30-b0d6d29837ce","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17069"},"specVersion":"0.1.0","time":"2024-04-09T22:57:09.742668879Z","eventData":"SUCCESS"}
{"id":"4263b2d4-ad38-4d7e-a4c0-59d9f6521456","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32960"},"specVersion":"0.1.0","time":"2024-04-09T22:57:09.827216255Z","eventData":"SUCCESS"}
{"id":"b9574b20-5776-4e71-a362-e18556218757","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17071"},"specVersion":"0.1.0","time":"2024-04-09T22:57:11.336087922Z","eventData":"SUCCESS"}
{"id":"ca2f053b-c936-4a7f-92f2-4b21f62d2252","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32962"},"specVersion":"0.1.0","time":"2024-04-09T22:57:11.373917880Z","eventData":"SUCCESS"}
{"id":"ab746ef4-9793-4b29-81df-0e7fae1538d3","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17073"},"specVersion":"0.1.0","time":"2024-04-09T22:57:12.764087214Z","eventData":"SUCCESS"}
{"id":"60dcba90-1cf1-4018-a9a7-19b3eec5ed55","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32964"},"specVersion":"0.1.0","time":"2024-04-09T22:57:12.796650298Z","eventData":"SUCCESS"}
{"id":"eb2d20fb-24de-44d4-bdf2-033ba9e8e281","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17075"},"specVersion":"0.1.0","time":"2024-04-09T22:57:14.123940465Z","eventData":"SUCCESS"}
{"id":"21b4840a-af5d-4785-a79e-a4fddd4acd3b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32966"},"specVersion":"0.1.0","time":"2024-04-09T22:57:14.158265590Z","eventData":"SUCCESS"}
{"id":"e88a3bcf-1bdb-4a79-aebd-7afc09064716","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17077"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.534253132Z","eventData":"SUCCESS"}
{"id":"c0178ae2-dd59-45de-a835-74161eb10843","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32968"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.565131466Z","eventData":"SUCCESS"}
{"id":"451b2171-737d-4506-a0f7-2c4ac6e78f53","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32969"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.693036716Z","eventData":"SUCCESS"}
{"id":"34f347bf-e604-4f18-b2e0-ee2968086384","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17092"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.579152217Z","eventData":"SUCCESS"}
{"id":"d02d0408-fac0-42eb-8be4-f0649aedffb2","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32983"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.597597925Z","eventData":"SUCCESS"}
{"id":"08438b0d-c1f1-4fa4-afdc-1843f88fbcf8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17094"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.624725050Z","eventData":"SUCCESS"}
{"id":"cdc7a87b-9fe1-4016-8e46-7a45ccd66d46","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28530"},"specVersion":"0.1.0","time":"2024-04-09T22:57:18.119768675Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"replicationFactor\" : {      \"min\" : 2,      \"max\" : 2    },    \"numPartition\" : {      \"min\" : 1,      \"max\" : 3    }  }}"}}
{"id":"2cc00de7-bb9d-4c28-b305-135de9138061","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28531"},"specVersion":"0.1.0","time":"2024-04-09T22:57:18.318868092Z","eventData":{"method":"GET","path":"/admin/interceptors/v1/vcluster/teamA","body":null}}
{"id":"63b9ef30-2fd7-4db1-9d16-7610cfdf9272","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17109"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.217374842Z","eventData":"SUCCESS"}
{"id":"36de93e8-b1a6-47ff-bacf-d79a3b89b717","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33000"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.238897509Z","eventData":"SUCCESS"}
{"id":"35607bf6-05ea-4f83-b87a-2e9130f21fcc","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33000"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.258906592Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin","message":"Request parameters do not satisfy the configured policy. Topic 'roads' with number partitions is '100', must not be greater than 3. Topic 'roads' with replication factor is '1', must not be less than 2"}}
{"id":"bc94cc84-51f9-4dca-b918-9d09fe18fffd","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17111"},"specVersion":"0.1.0","time":"2024-04-09T22:57:20.582032760Z","eventData":"SUCCESS"}
{"id":"1f2a13e1-79d8-4741-a7cf-663b8c69a1a9","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33002"},"specVersion":"0.1.0","time":"2024-04-09T22:57:20.603914426Z","eventData":"SUCCESS"}
{"id":"13aa671a-eba1-4822-8b4a-790b19e6f517","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28536"},"specVersion":"0.1.0","time":"2024-04-09T22:57:21.149915843Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-alter-topic","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"retentionMs\" : {      \"min\" : 86400000,      \"max\" : 432000000    }  }}"}}
{"id":"0322d61d-f26b-4897-b190-ef31faeb144a","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17114"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.234666177Z","eventData":"SUCCESS"}
{"id":"12a03f8c-eb46-4297-ac05-c0d43f7c6a45","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6971","remoteAddress":"/192.168.65.1:44385"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.258857260Z","eventData":"SUCCESS"}
{"id":"ac9d937d-daa7-482a-95e8-7e21c55ff51e","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:44385"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.322798385Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin","message":"Request parameters do not satisfy the configured policy. Resource 'roads' with retention.ms is '5184000000', must not be greater than '432000000'"}}
{"id":"1c5884ec-6ea6-4974-846e-0fc3a1881bb8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17116"},"specVersion":"0.1.0","time":"2024-04-09T22:57:23.728982886Z","eventData":"SUCCESS"}
{"id":"3854b5d0-bb85-4735-be81-0597237ad8b1","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33007"},"specVersion":"0.1.0","time":"2024-04-09T22:57:23.748231761Z","eventData":"SUCCESS"}
{"id":"fee03330-e546-4297-bf83-8038a2f0ed55","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28541"},"specVersion":"0.1.0","time":"2024-04-09T22:57:24.302672303Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-produce","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"acks\" : {      \"value\" : [ -1 ],      \"action\" : \"BLOCK\"    },    \"compressions\" : {      \"value\" : [ \"NONE\", \"GZIP\" ],      \"action\" : \"BLOCK\"    }  }}"}}
{"id":"930007bb-3325-45f7-875e-b374ebc54548","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17119"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.298030595Z","eventData":"SUCCESS"}
{"id":"164bdf3d-d1b8-4849-9188-5ef823d8cd0b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33010"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.813463304Z","eventData":"SUCCESS"}
{"id":"b18e0515-feb4-45d8-aadc-50bc76a75c5d","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33010"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.864088137Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin","message":"Request parameters do not satisfy the configured policy. Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1. Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]"}}
{"id":"2d45242b-ea94-43d1-8055-c4972f6b8481","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17121"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.192247179Z","eventData":"SUCCESS"}
{"id":"c49ce88e-8f18-48c4-bf71-66f11607c03e","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33012"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.220203596Z","eventData":"SUCCESS"}
{"id":"b7710805-24c4-4c2a-a4ab-53701928a435","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28558"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.680550388Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"maximumBytesPerSecond\" : 1  }}"}}
{"id":"4659321f-3f7f-4564-a5aa-e8179a0682b7","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17148"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.620101472Z","eventData":"SUCCESS"}
{"id":"78366d0c-a400-4365-9f7d-41e3c7030bb3","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33039"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.648120222Z","eventData":"SUCCESS"}
{"id":"1cf909c0-2610-412c-b257-15a5af81b682","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33039"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.662161305Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin","message":"Client produced (108) bytes, which is more than 1 bytes per second, producer will be throttled by 44 milliseconds"}}
{"id":"f310f6a4-54ab-46fd-b956-9177bdde8416","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28577"},"specVersion":"0.1.0","time":"2024-04-09T22:57:33.671817502Z","eventData":{"method":"DELETE","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate","body":null}}
{"id":"17f183eb-56c6-4d0b-bc4f-e7b01f0d9ee1","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28578"},"specVersion":"0.1.0","time":"2024-04-09T22:57:33.726142043Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"groupId\" : {      \"value\" : \"my-group.*\",      \"action\" : \"BLOCK\"    }  }}"}}
{"id":"c2092f02-6d9d-447d-912c-07a3d9fdd04d","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17156"},"specVersion":"0.1.0","time":"2024-04-09T22:57:34.717949919Z","eventData":"SUCCESS"}
{"id":"8b2f1ed7-4d7b-426a-a105-d3961ae8c6a0","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6971","remoteAddress":"/192.168.65.1:44427"},"specVersion":"0.1.0","time":"2024-04-09T22:57:34.745343752Z","eventData":"SUCCESS"}
{"id":"cac027b2-a847-48b2-be7a-0abc76d70e2a","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:44427"},"specVersion":"0.1.0","time":"2024-04-09T22:57:34.751896794Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin","message":"Request parameters do not satisfy the configured policy. GroupId 'group-not-within-policy' is invalid, naming convention must match with regular expression my-group.*"}}
{"id":"13017735-b554-4672-820e-dd9d3712bb3b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17186"},"specVersion":"0.1.0","time":"2024-04-09T22:57:40.668242255Z","eventData":"SUCCESS"}
{"id":"dd992af8-723d-42e2-817a-b415a1540cd0","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33077"},"specVersion":"0.1.0","time":"2024-04-09T22:57:40.696821713Z","eventData":"SUCCESS"}
{"id":"02b0a54c-e3ab-4929-ab94-5c28f33b513d","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33078"},"specVersion":"0.1.0","time":"2024-04-09T22:57:40.753620297Z","eventData":"SUCCESS"}
{"id":"36b877e3-44b7-4e03-9359-b8401a953f7a","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28636"},"specVersion":"0.1.0","time":"2024-04-09T22:57:51.477988135Z","eventData":{"method":"DELETE","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy","body":null}}
{"id":"e6ad7376-82f6-4a66-b31c-79d444a0af04","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28637"},"specVersion":"0.1.0","time":"2024-04-09T22:57:51.520679010Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"maximumConnectionsPerSecond\" : 1,    \"action\" : \"BLOCK\"  }}"}}
{"id":"99a89772-b93e-4350-8a10-f27efe8dc7f0","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17215"},"specVersion":"0.1.0","time":"2024-04-09T22:57:52.632705802Z","eventData":"SUCCESS"}
{"id":"be62c161-ec67-407d-8f84-770c45b26ac2","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17216"},"specVersion":"0.1.0","time":"2024-04-09T22:57:52.662057302Z","eventData":"SUCCESS"}
{"id":"6d1ea918-9336-45f7-b804-a284e1f6af74","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17216"},"specVersion":"0.1.0","time":"2024-04-09T22:57:53.147906178Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"59f69ea2-21e9-4977-babf-0736597bd9e2","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17217"},"specVersion":"0.1.0","time":"2024-04-09T22:57:53.172082553Z","eventData":"SUCCESS"}
{"id":"fb93c0ca-9a0d-4ff0-84d2-55c2f8ed5581","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17217"},"specVersion":"0.1.0","time":"2024-04-09T22:57:53.966183386Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"f387ee8f-48ac-42c2-b731-79f729b07f14","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:57:54.088428886Z","eventData":"SUCCESS"}
{"id":"c5a0c28e-7cd4-48a1-91d3-0db9852919ac","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17219"},"specVersion":"0.1.0","time":"2024-04-09T22:57:54.131941553Z","eventData":"SUCCESS"}
{"id":"1f146ee8-f7ad-4417-a22d-11e736a0dd7e","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17219"},"specVersion":"0.1.0","time":"2024-04-09T22:57:55.035045178Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"34e21d73-d81f-4323-8567-cb879ef6a697","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17220"},"specVersion":"0.1.0","time":"2024-04-09T22:57:55.191588804Z","eventData":"SUCCESS"}
{"id":"699f5c43-24f2-4cdc-92e0-6d344bf27759","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17220"},"specVersion":"0.1.0","time":"2024-04-09T22:57:55.281730804Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"866f66d8-bab2-4fd0-918e-c420414b2737","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17221"},"specVersion":"0.1.0","time":"2024-04-09T22:57:55.725690095Z","eventData":"SUCCESS"}
{"id":"e7a9739e-735d-41cf-bdb1-d7a6090cda32","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:57:57.299099930Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"d09919b3-7e0f-46f8-85e0-14d5f13de7a1","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:57:59.436547625Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"0a221977-8b79-4597-86e4-a72dc7c7a914","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:57:59.998596417Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"352db6bd-3404-4c0e-9faf-4db49839f775","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:58:01.371221209Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"0db3dd4e-96d2-405a-922b-66eb32f8f898","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:58:02.376090668Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"5df7844c-3575-4182-b345-c0e49e721df7","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:58:05.622984419Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"d36c3263-c762-4da0-b12e-60fcad058c32","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17221"},"specVersion":"0.1.0","time":"2024-04-09T22:58:06.339291586Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"adceb663-6a62-4be1-9ded-922e5f27e403","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17221"},"specVersion":"0.1.0","time":"2024-04-09T22:58:06.339283545Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"077f1f0c-d54c-4371-8c9f-428d4ca54736","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17221"},"specVersion":"0.1.0","time":"2024-04-09T22:58:07.375596878Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
[2024-04-10 02:58:11,881] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 68 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/1Q5oODDmn3dqxGO5jiTIWKFvh.svg)](https://asciinema.org/a/1Q5oODDmn3dqxGO5jiTIWKFvh)

</details>

## Remove interceptor guard-limit-connection



<details open>
<summary>Command</summary>



```sh
curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection" \
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

[![asciicast](https://asciinema.org/a/rtrzHuS3pnHgEvRCRrTmHoiYh.svg)](https://asciinema.org/a/rtrzHuS3pnHgEvRCRrTmHoiYh)

</details>

## Adding interceptor guard-agressive-auto-commit

Let's block aggressive auto-commits strategies

Creating the interceptor named `guard-agressive-auto-commit` of the plugin `io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin",
  "priority" : 100,
  "config" : {
    "maximumCommitsPerMinute" : 1,
    "action" : "BLOCK"
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-33-guard-agressive-auto-commit.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-agressive-auto-commit" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-33-guard-agressive-auto-commit.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin",
  "priority": 100,
  "config": {
    "maximumCommitsPerMinute": 1,
    "action": "BLOCK"
  }
}
{
  "message": "guard-agressive-auto-commit is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/RsHWMRFo9Q9326Vf1FbqZPjES.svg)](https://asciinema.org/a/RsHWMRFo9Q9326Vf1FbqZPjES)

</details>

## Consuming from cars

Consuming from cars in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group group-with-aggressive-autocommit | jq
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 02:58:23,579] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
[2024-04-10 02:58:23,661] ERROR [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] Offset commit failed on partition cars-0 at offset 5: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-04-10 02:58:23,814] ERROR [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] Offset commit failed on partition cars-0 at offset 5: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-04-10 02:58:23,815] WARN [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] Asynchronous auto-commit of offsets {cars-0=OffsetAndMetadata{offset=5, leaderEpoch=0, metadata=''}} failed: Unexpected error in commit: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-04-10 02:58:23,815] WARN [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] Synchronous auto-commit of offsets {cars-0=OffsetAndMetadata{offset=5, leaderEpoch=0, metadata=''}} failed: Unexpected error in commit: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
Processed a total of 5 messages
{
  "type": "Ferrari",
  "color": "red",
  "price": 10000
}
{
  "type": "RollsRoyce",
  "color": "black",
  "price": 9000
}
{
  "type": "Mercedes",
  "color": "black",
  "price": 6000
}
{
  "type": "Fiat",
  "color": "red",
  "price": -1
}
{
  "type": "Fiat",
  "color": "red",
  "price": -1
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/U2kX9rRWFTAKmBgGsMnvnoRsU.svg)](https://asciinema.org/a/U2kX9rRWFTAKmBgGsMnvnoRsU)

</details>

## Check in the audit log that connection was denied

Check in the audit log that connection was denied in cluster `kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _conduktor_gateway_auditlogs \
    --from-beginning \
    --timeout-ms 3000 \| jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin")'
```


returns 1 event
```json
{
  "id" : "f491b864-7b6e-4077-a5f2-591206f23278",
  "source" : "krn://cluster=aL7VOesuSJe5AwmMCmTBPw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:16639"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T22:56:11.774274380Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin",
    "message" : "Client calls join group (group-with-aggressive-autocommit) exceed the limitation of 1 commits per minute"
  }
}
```



</details>
<details>
<summary>Output</summary>

```
{"id":"ad5d2cbf-2bd1-4dce-8d29-1c42939922e1","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28491"},"specVersion":"0.1.0","time":"2024-04-09T22:57:08.780478796Z","eventData":{"method":"POST","path":"/admin/vclusters/v1/vcluster/teamA/username/sa","body":"{\"lifeTimeSeconds\": 7776000}"}}
{"id":"7419d31b-b9ac-468b-bc30-b0d6d29837ce","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17069"},"specVersion":"0.1.0","time":"2024-04-09T22:57:09.742668879Z","eventData":"SUCCESS"}
{"id":"4263b2d4-ad38-4d7e-a4c0-59d9f6521456","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32960"},"specVersion":"0.1.0","time":"2024-04-09T22:57:09.827216255Z","eventData":"SUCCESS"}
{"id":"b9574b20-5776-4e71-a362-e18556218757","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17071"},"specVersion":"0.1.0","time":"2024-04-09T22:57:11.336087922Z","eventData":"SUCCESS"}
{"id":"ca2f053b-c936-4a7f-92f2-4b21f62d2252","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32962"},"specVersion":"0.1.0","time":"2024-04-09T22:57:11.373917880Z","eventData":"SUCCESS"}
{"id":"ab746ef4-9793-4b29-81df-0e7fae1538d3","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17073"},"specVersion":"0.1.0","time":"2024-04-09T22:57:12.764087214Z","eventData":"SUCCESS"}
{"id":"60dcba90-1cf1-4018-a9a7-19b3eec5ed55","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32964"},"specVersion":"0.1.0","time":"2024-04-09T22:57:12.796650298Z","eventData":"SUCCESS"}
{"id":"eb2d20fb-24de-44d4-bdf2-033ba9e8e281","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17075"},"specVersion":"0.1.0","time":"2024-04-09T22:57:14.123940465Z","eventData":"SUCCESS"}
{"id":"21b4840a-af5d-4785-a79e-a4fddd4acd3b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32966"},"specVersion":"0.1.0","time":"2024-04-09T22:57:14.158265590Z","eventData":"SUCCESS"}
{"id":"e88a3bcf-1bdb-4a79-aebd-7afc09064716","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17077"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.534253132Z","eventData":"SUCCESS"}
{"id":"c0178ae2-dd59-45de-a835-74161eb10843","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32968"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.565131466Z","eventData":"SUCCESS"}
{"id":"451b2171-737d-4506-a0f7-2c4ac6e78f53","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32969"},"specVersion":"0.1.0","time":"2024-04-09T22:57:15.693036716Z","eventData":"SUCCESS"}
{"id":"34f347bf-e604-4f18-b2e0-ee2968086384","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17092"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.579152217Z","eventData":"SUCCESS"}
{"id":"d02d0408-fac0-42eb-8be4-f0649aedffb2","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:32983"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.597597925Z","eventData":"SUCCESS"}
{"id":"08438b0d-c1f1-4fa4-afdc-1843f88fbcf8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17094"},"specVersion":"0.1.0","time":"2024-04-09T22:57:17.624725050Z","eventData":"SUCCESS"}
{"id":"cdc7a87b-9fe1-4016-8e46-7a45ccd66d46","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28530"},"specVersion":"0.1.0","time":"2024-04-09T22:57:18.119768675Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"replicationFactor\" : {      \"min\" : 2,      \"max\" : 2    },    \"numPartition\" : {      \"min\" : 1,      \"max\" : 3    }  }}"}}
{"id":"2cc00de7-bb9d-4c28-b305-135de9138061","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28531"},"specVersion":"0.1.0","time":"2024-04-09T22:57:18.318868092Z","eventData":{"method":"GET","path":"/admin/interceptors/v1/vcluster/teamA","body":null}}
{"id":"63b9ef30-2fd7-4db1-9d16-7610cfdf9272","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17109"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.217374842Z","eventData":"SUCCESS"}
{"id":"36de93e8-b1a6-47ff-bacf-d79a3b89b717","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33000"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.238897509Z","eventData":"SUCCESS"}
{"id":"35607bf6-05ea-4f83-b87a-2e9130f21fcc","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33000"},"specVersion":"0.1.0","time":"2024-04-09T22:57:19.258906592Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin","message":"Request parameters do not satisfy the configured policy. Topic 'roads' with number partitions is '100', must not be greater than 3. Topic 'roads' with replication factor is '1', must not be less than 2"}}
{"id":"bc94cc84-51f9-4dca-b918-9d09fe18fffd","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17111"},"specVersion":"0.1.0","time":"2024-04-09T22:57:20.582032760Z","eventData":"SUCCESS"}
{"id":"1f2a13e1-79d8-4741-a7cf-663b8c69a1a9","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33002"},"specVersion":"0.1.0","time":"2024-04-09T22:57:20.603914426Z","eventData":"SUCCESS"}
{"id":"13aa671a-eba1-4822-8b4a-790b19e6f517","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28536"},"specVersion":"0.1.0","time":"2024-04-09T22:57:21.149915843Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-alter-topic","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"retentionMs\" : {      \"min\" : 86400000,      \"max\" : 432000000    }  }}"}}
{"id":"0322d61d-f26b-4897-b190-ef31faeb144a","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17114"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.234666177Z","eventData":"SUCCESS"}
{"id":"12a03f8c-eb46-4297-ac05-c0d43f7c6a45","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6971","remoteAddress":"/192.168.65.1:44385"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.258857260Z","eventData":"SUCCESS"}
{"id":"ac9d937d-daa7-482a-95e8-7e21c55ff51e","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:44385"},"specVersion":"0.1.0","time":"2024-04-09T22:57:22.322798385Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin","message":"Request parameters do not satisfy the configured policy. Resource 'roads' with retention.ms is '5184000000', must not be greater than '432000000'"}}
{"id":"1c5884ec-6ea6-4974-846e-0fc3a1881bb8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17116"},"specVersion":"0.1.0","time":"2024-04-09T22:57:23.728982886Z","eventData":"SUCCESS"}
{"id":"3854b5d0-bb85-4735-be81-0597237ad8b1","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33007"},"specVersion":"0.1.0","time":"2024-04-09T22:57:23.748231761Z","eventData":"SUCCESS"}
{"id":"fee03330-e546-4297-bf83-8038a2f0ed55","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28541"},"specVersion":"0.1.0","time":"2024-04-09T22:57:24.302672303Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-produce","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"acks\" : {      \"value\" : [ -1 ],      \"action\" : \"BLOCK\"    },    \"compressions\" : {      \"value\" : [ \"NONE\", \"GZIP\" ],      \"action\" : \"BLOCK\"    }  }}"}}
{"id":"930007bb-3325-45f7-875e-b374ebc54548","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17119"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.298030595Z","eventData":"SUCCESS"}
{"id":"164bdf3d-d1b8-4849-9188-5ef823d8cd0b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33010"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.813463304Z","eventData":"SUCCESS"}
{"id":"b18e0515-feb4-45d8-aadc-50bc76a75c5d","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33010"},"specVersion":"0.1.0","time":"2024-04-09T22:57:25.864088137Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin","message":"Request parameters do not satisfy the configured policy. Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1. Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]"}}
{"id":"2d45242b-ea94-43d1-8055-c4972f6b8481","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17121"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.192247179Z","eventData":"SUCCESS"}
{"id":"c49ce88e-8f18-48c4-bf71-66f11607c03e","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33012"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.220203596Z","eventData":"SUCCESS"}
{"id":"b7710805-24c4-4c2a-a4ab-53701928a435","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28558"},"specVersion":"0.1.0","time":"2024-04-09T22:57:27.680550388Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"maximumBytesPerSecond\" : 1  }}"}}
{"id":"4659321f-3f7f-4564-a5aa-e8179a0682b7","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17148"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.620101472Z","eventData":"SUCCESS"}
{"id":"78366d0c-a400-4365-9f7d-41e3c7030bb3","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33039"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.648120222Z","eventData":"SUCCESS"}
{"id":"1cf909c0-2610-412c-b257-15a5af81b682","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33039"},"specVersion":"0.1.0","time":"2024-04-09T22:57:28.662161305Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin","message":"Client produced (108) bytes, which is more than 1 bytes per second, producer will be throttled by 44 milliseconds"}}
{"id":"f310f6a4-54ab-46fd-b956-9177bdde8416","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28577"},"specVersion":"0.1.0","time":"2024-04-09T22:57:33.671817502Z","eventData":{"method":"DELETE","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate","body":null}}
{"id":"17f183eb-56c6-4d0b-bc4f-e7b01f0d9ee1","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28578"},"specVersion":"0.1.0","time":"2024-04-09T22:57:33.726142043Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"groupId\" : {      \"value\" : \"my-group.*\",      \"action\" : \"BLOCK\"    }  }}"}}
{"id":"c2092f02-6d9d-447d-912c-07a3d9fdd04d","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17156"},"specVersion":"0.1.0","time":"2024-04-09T22:57:34.717949919Z","eventData":"SUCCESS"}
{"id":"8b2f1ed7-4d7b-426a-a105-d3961ae8c6a0","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6971","remoteAddress":"/192.168.65.1:44427"},"specVersion":"0.1.0","time":"2024-04-09T22:57:34.745343752Z","eventData":"SUCCESS"}
{"id":"cac027b2-a847-48b2-be7a-0abc76d70e2a","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:44427"},"specVersion":"0.1.0","time":"2024-04-09T22:57:34.751896794Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin","message":"Request parameters do not satisfy the configured policy. GroupId 'group-not-within-policy' is invalid, naming convention must match with regular expression my-group.*"}}
{"id":"13017735-b554-4672-820e-dd9d3712bb3b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17186"},"specVersion":"0.1.0","time":"2024-04-09T22:57:40.668242255Z","eventData":"SUCCESS"}
{"id":"dd992af8-723d-42e2-817a-b415a1540cd0","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33077"},"specVersion":"0.1.0","time":"2024-04-09T22:57:40.696821713Z","eventData":"SUCCESS"}
{"id":"02b0a54c-e3ab-4929-ab94-5c28f33b513d","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33078"},"specVersion":"0.1.0","time":"2024-04-09T22:57:40.753620297Z","eventData":"SUCCESS"}
{"id":"36b877e3-44b7-4e03-9359-b8401a953f7a","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28636"},"specVersion":"0.1.0","time":"2024-04-09T22:57:51.477988135Z","eventData":{"method":"DELETE","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy","body":null}}
{"id":"e6ad7376-82f6-4a66-b31c-79d444a0af04","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28637"},"specVersion":"0.1.0","time":"2024-04-09T22:57:51.520679010Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"maximumConnectionsPerSecond\" : 1,    \"action\" : \"BLOCK\"  }}"}}
{"id":"99a89772-b93e-4350-8a10-f27efe8dc7f0","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17215"},"specVersion":"0.1.0","time":"2024-04-09T22:57:52.632705802Z","eventData":"SUCCESS"}
{"id":"be62c161-ec67-407d-8f84-770c45b26ac2","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17216"},"specVersion":"0.1.0","time":"2024-04-09T22:57:52.662057302Z","eventData":"SUCCESS"}
{"id":"6d1ea918-9336-45f7-b804-a284e1f6af74","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17216"},"specVersion":"0.1.0","time":"2024-04-09T22:57:53.147906178Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"59f69ea2-21e9-4977-babf-0736597bd9e2","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17217"},"specVersion":"0.1.0","time":"2024-04-09T22:57:53.172082553Z","eventData":"SUCCESS"}
{"id":"fb93c0ca-9a0d-4ff0-84d2-55c2f8ed5581","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17217"},"specVersion":"0.1.0","time":"2024-04-09T22:57:53.966183386Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"f387ee8f-48ac-42c2-b731-79f729b07f14","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:57:54.088428886Z","eventData":"SUCCESS"}
{"id":"c5a0c28e-7cd4-48a1-91d3-0db9852919ac","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17219"},"specVersion":"0.1.0","time":"2024-04-09T22:57:54.131941553Z","eventData":"SUCCESS"}
{"id":"1f146ee8-f7ad-4417-a22d-11e736a0dd7e","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17219"},"specVersion":"0.1.0","time":"2024-04-09T22:57:55.035045178Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"34e21d73-d81f-4323-8567-cb879ef6a697","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17220"},"specVersion":"0.1.0","time":"2024-04-09T22:57:55.191588804Z","eventData":"SUCCESS"}
{"id":"699f5c43-24f2-4cdc-92e0-6d344bf27759","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17220"},"specVersion":"0.1.0","time":"2024-04-09T22:57:55.281730804Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"866f66d8-bab2-4fd0-918e-c420414b2737","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17221"},"specVersion":"0.1.0","time":"2024-04-09T22:57:55.725690095Z","eventData":"SUCCESS"}
{"id":"e7a9739e-735d-41cf-bdb1-d7a6090cda32","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:57:57.299099930Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"d09919b3-7e0f-46f8-85e0-14d5f13de7a1","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:57:59.436547625Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"0a221977-8b79-4597-86e4-a72dc7c7a914","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:57:59.998596417Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"352db6bd-3404-4c0e-9faf-4db49839f775","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:58:01.371221209Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"0db3dd4e-96d2-405a-922b-66eb32f8f898","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:58:02.376090668Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"5df7844c-3575-4182-b345-c0e49e721df7","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:33108"},"specVersion":"0.1.0","time":"2024-04-09T22:58:05.622984419Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"d36c3263-c762-4da0-b12e-60fcad058c32","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17221"},"specVersion":"0.1.0","time":"2024-04-09T22:58:06.339291586Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"adceb663-6a62-4be1-9ded-922e5f27e403","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17221"},"specVersion":"0.1.0","time":"2024-04-09T22:58:06.339283545Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"077f1f0c-d54c-4371-8c9f-428d4ca54736","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17221"},"specVersion":"0.1.0","time":"2024-04-09T22:58:07.375596878Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin","message":"Client connections exceed the limitation of 1 connections per second"}}
{"id":"42970e6c-fe67-4c2a-a710-dc97920488af","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28697"},"specVersion":"0.1.0","time":"2024-04-09T22:58:12.421261672Z","eventData":{"method":"DELETE","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection","body":null}}
{"id":"8ee44f83-3556-427e-9dab-05e82efed49d","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"192.168.224.7:8888","remoteAddress":"192.168.65.1:28698"},"specVersion":"0.1.0","time":"2024-04-09T22:58:12.472074131Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-agressive-auto-commit","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"maximumCommitsPerMinute\" : 1,    \"action\" : \"BLOCK\"  }}"}}
{"id":"139cca11-cab6-4955-8794-dc1b6e555959","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17276"},"specVersion":"0.1.0","time":"2024-04-09T22:58:13.449501673Z","eventData":"SUCCESS"}
{"id":"211d12bd-9a3e-43d5-8008-61ce82c20910","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6969","remoteAddress":"/192.168.65.1:17277"},"specVersion":"0.1.0","time":"2024-04-09T22:58:13.475080340Z","eventData":"SUCCESS"}
{"id":"7ed49d4f-4f32-4489-a89e-44916dc35a5a","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/192.168.224.7:6970","remoteAddress":"/192.168.65.1:33168"},"specVersion":"0.1.0","time":"2024-04-09T22:58:13.536606090Z","eventData":"SUCCESS"}
{"id":"b0402da8-1564-48e1-b1d1-21f3cdbadcd1","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17277"},"specVersion":"0.1.0","time":"2024-04-09T22:58:23.599225053Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin","message":"Client calls join group (group-with-aggressive-autocommit) exceed the limitation of 1 commits per minute"}}
{"id":"0effbe99-e1a3-404a-a41b-955c7aaa7ecf","source":"krn://cluster=OnTSUQoUS4-lkvgciS_aIA","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:17277"},"specVersion":"0.1.0","time":"2024-04-09T22:58:23.801088511Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin","message":"Client calls join group (group-with-aggressive-autocommit) exceed the limitation of 1 commits per minute"}}
[2024-04-10 02:58:31,285] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 75 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/QOgKoSj1adkzjCSlUgGc94jw4.svg)](https://asciinema.org/a/QOgKoSj1adkzjCSlUgGc94jw4)

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
 Container gateway2  Stopping
 Container gateway1  Stopping
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
 Container kafka1  Stopping
 Container kafka3  Stopping
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container kafka-client  Stopped
 Container kafka-client  Removing
 Container kafka-client  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network safeguard_default  Removing
 Network safeguard_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/odZyXj7hVsfSGfUNYEgoHn07f.svg)](https://asciinema.org/a/odZyXj7hVsfSGfUNYEgoHn07f)

</details>

# Conclusion

Safeguard is really a game changer!

