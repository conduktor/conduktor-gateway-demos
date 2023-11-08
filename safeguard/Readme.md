# What is a safeguard?

Enforce your rules where it matters

Safeguard ensures that your teams follow your rules and can't break convention. 

Enable your teams, prevent common mistakes, protect your infra.

## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/QzilZiq9KPXN5gmHw6UAhink6.svg)](https://asciinema.org/a/QzilZiq9KPXN5gmHw6UAhink6)

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
gateway1          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway1          33 seconds ago   Up 21 seconds (healthy)   0.0.0.0:6969-6971->6969-6971/tcp, 0.0.0.0:8888->8888/tcp
gateway2          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway2          33 seconds ago   Up 21 seconds (healthy)   0.0.0.0:7969-7971->7969-7971/tcp, 0.0.0.0:8889->8888/tcp
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            33 seconds ago   Up 27 seconds (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            33 seconds ago   Up 27 seconds (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
kafka3            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka3            33 seconds ago   Up 27 seconds (healthy)   9092/tcp, 0.0.0.0:19094->19094/tcp
schema-registry   confluentinc/cp-schema-registry:latest   "/etc/confluent/dock…"   schema-registry   33 seconds ago   Up 21 seconds (healthy)   0.0.0.0:8081->8081/tcp
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
 Network safeguard_default  Creating
 Network safeguard_default  Created
 Container zookeeper  Creating
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka3  Created
 Container kafka2  Created
 Container kafka1  Created
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Creating
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
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
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container kafka1  Started
 Container kafka3  Started
 Container kafka2  Started
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container gateway2  Starting
 Container kafka3  Healthy
 Container schema-registry  Starting
 Container kafka2  Healthy
 Container gateway1  Starting
 Container gateway2  Started
 Container schema-registry  Started
 Container gateway1  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container zookeeper  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzc0MTYzNH0.l23nxTUqZrBxd8k0GzZlJ4wU-20CYgMtqPjiXrHnx88';
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
      


## Producing 3 messages in `cars`

Produce 3 records to the cars topic.

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

<details>
  <summary>Realtime command output</summary>

  ![Producing 3 messages in `cars`](images/step-08-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

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
      


## Consume the `cars` topic

Let's confirm the 3 cars are there by consuming from the `cars` topic.

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consume the `cars` topic](images/step-09-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --max-messages 3 \
    --timeout-ms 10000 \
 | jq
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
      


## Describing topic `cars`

Replication factor is 1? 

This is bad: we can lose data!

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --describe \
    --topic cars
```

<details>
  <summary>Realtime command output</summary>

  ![Describing topic `cars`](images/step-10-DESCRIBE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --describe \
    --topic cars
Topic: cars	TopicId: itGe3ZQXTwWqZTq1RdfxZw	PartitionCount: 1	ReplicationFactor: 1	Configs: 
	Topic: cars	Partition: 0	Leader: 3	Replicas: 3	Isr: 3

```

</details>
      


## Adding interceptor `guard-on-create-topic`

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

```sh
cat step-11-guard-on-create-topic.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-11-guard-on-create-topic.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `guard-on-create-topic`](images/step-11-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-11-guard-on-create-topic.json | jq
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

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-11-guard-on-create-topic.json | jq
{
  "message": "guard-on-create-topic is created"
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

  ![Listing interceptors for `teamA`](images/step-12-LIST_INTERCEPTORS.gif)

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
      "name": "guard-on-create-topic",
      "pluginClass": "io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin",
      "apiKey": null,
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
      


## Create a topic that is not within policy

Topic creation is denied by our policy

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



<details>
  <summary>Realtime command output</summary>

  ![Create a topic that is not within policy](images/step-13-CREATE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 100 \
    --create --if-not-exists \
    --topic roads
Error while executing topic command : Request parameters do not satisfy the configured policy. Topic 'roads' with number partitions is '100', must not be greater than 3. Topic 'roads' with replication factor is '1', must not be less than 2
[2024-01-23 00:22:38,511] ERROR org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Topic 'roads' with number partitions is '100', must not be greater than 3. Topic 'roads' with replication factor is '1', must not be less than 2
 (kafka.admin.TopicCommand$)

```

</details>
      


## Let's now create it again, with parameters within our policy

Perfect, it has been created

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 2 \
    --partitions 3 \
    --create --if-not-exists \
    --topic roads
```

<details>
  <summary>Realtime command output</summary>

  ![Let's now create it again, with parameters within our policy](images/step-14-CREATE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 2 \
    --partitions 3 \
    --create --if-not-exists \
    --topic roads
Created topic roads.

```

</details>
      


## Adding interceptor `guard-on-alter-topic`

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

```sh
cat step-15-guard-on-alter-topic.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-alter-topic" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-15-guard-on-alter-topic.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `guard-on-alter-topic`](images/step-15-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-15-guard-on-alter-topic.json | jq
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

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-alter-topic" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-15-guard-on-alter-topic.json | jq
{
  "message": "guard-on-alter-topic is created"
}

```

</details>
      


## Update 'cars' with a retention of 60 days

Altering the topic is denied by our policy

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



<details>
  <summary>Realtime command output</summary>

  ![Update 'cars' with a retention of 60 days](images/step-16-ALTER_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-configs \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --alter \
    --entity-type topics \
    --entity-name roads \
    --add-config retention.ms=5184000000
Error while executing config command with args '--bootstrap-server localhost:6969 --command-config teamA-sa.properties --alter --entity-type topics --entity-name roads --add-config retention.ms=5184000000'
java.util.concurrent.ExecutionException: org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Resource 'roads' with retention.ms is '5184000000', must not be greater than '432000000'
	at java.base/java.util.concurrent.CompletableFuture.reportGet(CompletableFuture.java:396)
	at java.base/java.util.concurrent.CompletableFuture.get(CompletableFuture.java:2096)
	at org.apache.kafka.common.internals.KafkaFutureImpl.get(KafkaFutureImpl.java:180)
	at kafka.admin.ConfigCommand$.alterConfig(ConfigCommand.scala:361)
	at kafka.admin.ConfigCommand$.processCommand(ConfigCommand.scala:328)
	at kafka.admin.ConfigCommand$.main(ConfigCommand.scala:97)
	at kafka.admin.ConfigCommand.main(ConfigCommand.scala)
Caused by: org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Resource 'roads' with retention.ms is '5184000000', must not be greater than '432000000'

```

</details>
      


## Update 'cars' with a retention of 3 days

Topic updated successfully

```sh
kafka-configs \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --alter \
    --entity-type topics \
    --entity-name roads \
    --add-config retention.ms=259200000
```

<details>
  <summary>Realtime command output</summary>

  ![Update 'cars' with a retention of 3 days](images/step-17-ALTER_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-configs \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --alter \
    --entity-type topics \
    --entity-name roads \
    --add-config retention.ms=259200000
Completed updating config for topic roads.

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
cat step-18-guard-on-produce.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-produce" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-18-guard-on-produce.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `guard-on-produce`](images/step-18-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-18-guard-on-produce.json | jq
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
    --data @step-18-guard-on-produce.json | jq
{
  "message": "guard-on-produce is created"
}

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

  ![Produce sample data to our `cars` topic without the right policies](images/step-19-PRODUCE.gif)

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
[2024-01-23 00:22:45,453] ERROR Error when sending message to topic cars with key: null, value: 40 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1. Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]

```

</details>
      


## Produce sample data to our `cars` topic that complies with our policy

Producing a record matching our policy

```sh
echo '{"type":"Fiat","color":"red","price":-1}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --request-required-acks -1 \
        --compression-codec gzip \
        --topic cars
```

<details>
  <summary>Realtime command output</summary>

  ![Produce sample data to our `cars` topic that complies with our policy](images/step-20-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

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
      


## Adding interceptor `produce-rate`

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

```sh
cat step-21-produce-rate.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-21-produce-rate.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `produce-rate`](images/step-21-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-21-produce-rate.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin",
  "priority": 100,
  "config": {
    "maximumBytesPerSecond": 1
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-21-produce-rate.json | jq
{
  "message": "produce-rate is created"
}

```

</details>
      


## Produce sample data

Do not match our produce rate policy

```sh
echo '{"type":"Fiat","color":"red","price":-1}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --request-required-acks -1 \
        --compression-codec none \
        --topic cars
```

<details>
  <summary>Realtime command output</summary>

  ![Produce sample data](images/step-22-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

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
      


## Check in the audit log that produce was throttled

Check in the audit log that produce was throttled in cluster `kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin")'
```


```json
{
  "id" : "a72db2e1-55c6-4b8d-b630-daba82e2e4dc",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19537"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:36.712918709Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin",
    "message" : "Client produced (108) bytes, which is more than 1 bytes per second, producer will be throttled by 942 milliseconds"
  }
}
```


<details>
  <summary>Realtime command output</summary>

  ![Check in the audit log that produce was throttled](images/step-23-AUDITLOG.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ProducerRateLimitingPolicyPlugin")'
[2024-01-23 00:22:52,795] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 37 messages

```

</details>
      


## Remove interceptor `produce-rate`



```sh
curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate" \
    --header 'Content-Type: application/json'
    --user 'admin:conduktor' \
    --silent | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Remove interceptor `produce-rate`](images/step-24-REMOVE_INTERCEPTORS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/produce-rate" \
    --header 'Content-Type: application/json'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
    --user 'admin:conduktor' \
    --silent | jq
step-24-REMOVE_INTERCEPTORS.sh: line 4: --user: command not found

```

</details>
      


## Adding interceptor `consumer-group-name-policy`

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

```sh
cat step-25-consumer-group-name-policy.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-25-consumer-group-name-policy.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `consumer-group-name-policy`](images/step-25-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-25-consumer-group-name-policy.json | jq
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

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-25-consumer-group-name-policy.json | jq
{
  "message": "consumer-group-name-policy is created"
}

```

</details>
      


## Consuming from `cars`

Consuming from `cars` in cluster `teamA`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group group-not-within-policy \
 | jq
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> Unexpected error in join group response: Request parameters do not satisfy the configured policy.
> ```



<details>
  <summary>Realtime command output</summary>

  ![Consuming from `cars`](images/step-26-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group group-not-within-policy \
 | jq
[2024-01-23 00:22:54,420] ERROR [Consumer clientId=console-consumer, groupId=group-not-within-policy] JoinGroup failed due to unexpected error: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-01-23 00:22:54,420] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.KafkaException: Unexpected error in join group response: Request parameters do not satisfy the configured policy.
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$JoinGroupResponseHandler.handle(AbstractCoordinator.java:711)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$JoinGroupResponseHandler.handle(AbstractCoordinator.java:603)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$CoordinatorResponseHandler.onSuccess(AbstractCoordinator.java:1270)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$CoordinatorResponseHandler.onSuccess(AbstractCoordinator.java:1245)
	at org.apache.kafka.clients.consumer.internals.RequestFuture$1.onSuccess(RequestFuture.java:206)
	at org.apache.kafka.clients.consumer.internals.RequestFuture.fireSuccess(RequestFuture.java:169)
	at org.apache.kafka.clients.consumer.internals.RequestFuture.complete(RequestFuture.java:129)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient$RequestFutureCompletionHandler.fireCompletion(ConsumerNetworkClient.java:617)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.firePendingCompletedRequests(ConsumerNetworkClient.java:427)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:312)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:251)
	at org.apache.kafka.clients.consumer.KafkaConsumer.pollForFetches(KafkaConsumer.java:1255)
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1186)
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1159)
	at kafka.tools.ConsoleConsumer$ConsumerWrapper.receive(ConsoleConsumer.scala:473)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:103)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:77)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:54)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Processed a total of 0 messages

```

</details>
      


## Check in the audit log that fetch was denied

Check in the audit log that fetch was denied in cluster `kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin")'
```


```json
{
  "id" : "3ec3038c-0a79-4380-bd25-d818f63a5a5f",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:47107"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:39.931147669Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin",
    "message" : "Request parameters do not satisfy the configured policy. GroupId 'group-not-within-policy' is invalid, naming convention must match with regular expression my-group.*"
  }
}
```


<details>
  <summary>Realtime command output</summary>

  ![Check in the audit log that fetch was denied](images/step-27-AUDITLOG.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin")'
[2024-01-23 00:22:58,935] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 41 messages
{
  "id": "6ec9eb8a-1db6-4ea6-a2ed-9840883312be",
  "source": "krn://cluster=n4EWs04xSSOBKT5X5C0m3w",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:21738"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:22:54.411529634Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ConsumerGroupPolicyPlugin",
    "message": "Request parameters do not satisfy the configured policy. GroupId 'group-not-within-policy' is invalid, naming convention must match with regular expression my-group.*"
  }
}

```

</details>
      


## Consuming from `cars`

Consuming from `cars` in cluster `teamA`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group my-group-within-policy \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `cars`](images/step-28-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group my-group-within-policy \
 | jq
[2024-01-23 00:23:10,517] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
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
      


## Remove interceptor `consumer-group-name-policy`



```sh
curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy" \
    --header 'Content-Type: application/json'
    --user 'admin:conduktor' \
    --silent | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Remove interceptor `consumer-group-name-policy`](images/step-29-REMOVE_INTERCEPTORS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/consumer-group-name-policy" \
    --header 'Content-Type: application/json'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
    --user 'admin:conduktor' \
    --silent | jq
step-29-REMOVE_INTERCEPTORS.sh: line 4: --user: command not found

```

</details>
      


## Adding interceptor `guard-limit-connection`

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

```sh
cat step-30-guard-limit-connection.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-30-guard-limit-connection.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `guard-limit-connection`](images/step-30-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-30-guard-limit-connection.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
  "priority": 100,
  "config": {
    "maximumConnectionsPerSecond": 1,
    "action": "BLOCK"
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-30-guard-limit-connection.json | jq
{
  "message": "guard-limit-connection is created"
}

```

</details>
      


## Consuming from `cars`

Consuming from `cars` in cluster `teamA`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group my-group-id-convention-cars \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `cars`](images/step-31-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group my-group-id-convention-cars \
 | jq
[2024-01-23 00:23:13,283] WARN [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] Received error POLICY_VIOLATION from node 3 when making an ApiVersionsRequest with correlation id 9. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-01-23 00:23:13,566] WARN [Consumer clientId=console-consumer, groupId=my-group-id-convention-cars] Received error POLICY_VIOLATION from node 1 when making an ApiVersionsRequest with correlation id 10. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-01-23 00:23:23,542] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
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
      


## Check in the audit log that connection was denied

Check in the audit log that connection was denied in cluster `kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin")'
```


```json
{
  "id" : "889ee5eb-912b-4ac2-94d5-7d7b740bfc0a",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21316"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:53.875919758Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "84e2fb64-37f7-40a5-a552-ce70c989477d",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19554"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:54.068550217Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "1f22c558-3c47-4f2f-9ba9-69c67e55e280",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21316"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:54.141790467Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "37b24da0-4884-4425-8ae8-8cd7255a924f",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21346"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:54.233646092Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "08ab8ec7-e786-4e9f-8fed-8cd822cf5fb1",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21316"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:54.747386176Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "8349c27d-c769-4aad-896a-e48f610f30b1",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19557"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:55.192520509Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "a23c05c7-e6f6-410d-a4d3-b885e18e8544",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:55.595506426Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "fecb8898-fefb-4b51-9e4b-29b16718863a",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21316"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:55.776284468Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "90c4b870-30ea-4aa7-a8f0-4005dc72d6f4",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21316"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:56.054942926Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "cf4f6016-8d23-421f-848c-11e0cda922fe",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:56.096950843Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "88e836fa-ef2d-4e0c-b42d-6abaec780c88",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19556"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:56.287724176Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "3988c491-8096-4c71-9513-4f7857a1ed97",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21316"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:56.854031635Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "120e5353-1c20-4f01-a742-7d0a06b7c95c",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:56.953551677Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "6980461a-76cb-459b-9dbc-4837f9af417d",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19556"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:57.053074677Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "47a5fa46-1ddd-4d59-b7b6-29b96396cee3",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:57.728568927Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "39f31664-1b95-4693-96b2-143fd230d28c",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21316"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:58.028819094Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "32ba70cc-3d98-4f6f-86a9-7998f17bcf53",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:58.057530135Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "33ae3526-23ec-4dea-bde8-bc627a1d56a8",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21316"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:59.143797803Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "ff2e88be-27d7-48dc-a88f-4e80a972f6ce",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:59.222904136Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "85bb2f1f-9950-4456-becf-f761957b5f84",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19556"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:59.349630719Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "1c65e219-4f36-4c11-b8a2-e05507c66694",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:59.661199011Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "96ff2e19-f380-4bc6-8665-7b9ed07b73b3",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21316"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:20:59.711108553Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "b0bf6fc0-d0b3-46e9-8224-fede52fba7e3",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21316"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:00.263639387Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "e46b6731-afb3-40e9-8a6a-15a440feb642",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:00.654150512Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "c03fc498-81af-49dc-b2de-5e9a8fdb2d34",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19556"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:00.930566179Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "662d6945-ef3e-410c-bc75-ef58532d81ee",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19556"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:01.398883345Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "6a567d65-29c7-4146-bb7e-79e2f30da313",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:01.731915554Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "bca6521a-b924-48cc-b6d9-581f85dc256d",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:02.007826929Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "c7229ecb-b251-44b0-b1e8-4362d6e8728c",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19556"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:02.091056971Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "84acc9b2-4b7c-4545-ab16-c39476f083de",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:02.421299054Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "2654ed75-685a-4bed-8326-23e93cab1481",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19556"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:02.485021804Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "2ffb2ef5-9eeb-448f-babf-3fcef37354bb",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:02.929359429Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "0b1f435c-07a6-4c3a-9074-cc912f253ea4",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:03.521446721Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "5335b84d-255b-4ed7-84b0-13b7eb389875",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19556"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:04.093383013Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "c243fe1e-d358-4aa6-9d21-31d659971b45",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:04.107369638Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "55a5a182-3d51-4d19-bb07-193d254bb894",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:04.512757222Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id" : "785ce248-d07f-4d48-bed1-9ee78f3274e4",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:21340"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:05.357740791Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message" : "Client connections exceed the limitation of 1 connections per second"
  }
}
```


<details>
  <summary>Realtime command output</summary>

  ![Check in the audit log that connection was denied](images/step-32-AUDITLOG.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin")'
{
  "id": "f464a103-d455-4e3d-888a-46078f1c291e",
  "source": "krn://cluster=n4EWs04xSSOBKT5X5C0m3w",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:21749"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:23:13.232996003Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message": "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id": "48c25392-7d44-41d9-a300-0ab256839916",
  "source": "krn://cluster=n4EWs04xSSOBKT5X5C0m3w",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:47522"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:23:13.561642045Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message": "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id": "e4d5c2dd-bad7-4672-ae71-b31460f1f17d",
  "source": "krn://cluster=n4EWs04xSSOBKT5X5C0m3w",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:21751"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:23:16.543739422Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message": "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id": "9e598604-89a1-4c69-80af-36023f51cb5e",
  "source": "krn://cluster=n4EWs04xSSOBKT5X5C0m3w",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:21751"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:23:17.701786422Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message": "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id": "c6e05a74-f3f5-40a7-98c4-70d059589d8a",
  "source": "krn://cluster=n4EWs04xSSOBKT5X5C0m3w",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:21751"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:23:18.413187173Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message": "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id": "bd4800a6-71f1-4978-8e9b-c7581d86c5db",
  "source": "krn://cluster=n4EWs04xSSOBKT5X5C0m3w",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:21751"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:23:22.626133008Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message": "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id": "442d22ca-cc4e-44b6-ab43-7b51e8d10253",
  "source": "krn://cluster=n4EWs04xSSOBKT5X5C0m3w",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:21751"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:23:23.620411842Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message": "Client connections exceed the limitation of 1 connections per second"
  }
}
{
  "id": "2b899421-6949-4522-b44b-56b2358dcf17",
  "source": "krn://cluster=n4EWs04xSSOBKT5X5C0m3w",
  "type": "SAFEGUARD",
  "authenticationPrinci[2024-01-23 00:23:28,289] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 58 messages
pal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:21751"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:23:23.765914425Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
    "message": "Client connections exceed the limitation of 1 connections per second"
  }
}

```

</details>
      


## Remove interceptor `guard-limit-connection`



```sh
curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection" \
    --header 'Content-Type: application/json'
    --user 'admin:conduktor' \
    --silent | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Remove interceptor `guard-limit-connection`](images/step-33-REMOVE_INTERCEPTORS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

curl \
    --request DELETE "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection" \
    --header 'Content-Type: application/json'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
    --user 'admin:conduktor' \
    --silent | jq
step-33-REMOVE_INTERCEPTORS.sh: line 4: --user: command not found

```

</details>
      


## Adding interceptor `guard-agressive-auto-commit`

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

```sh
cat step-34-guard-agressive-auto-commit.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-agressive-auto-commit" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-34-guard-agressive-auto-commit.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `guard-agressive-auto-commit`](images/step-34-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-34-guard-agressive-auto-commit.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin",
  "priority": 100,
  "config": {
    "maximumCommitsPerMinute": 1,
    "action": "BLOCK"
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-agressive-auto-commit" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-34-guard-agressive-auto-commit.json | jq
{
  "message": "guard-agressive-auto-commit is created"
}

```

</details>
      


## Consuming from `cars`

Consuming from `cars` in cluster `teamA`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group group-with-aggressive-autocommit \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `cars`](images/step-35-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group group-with-aggressive-autocommit \
 | jq
[2024-01-23 00:23:30,434] WARN [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] Received error POLICY_VIOLATION from node 2147483646 when making an ApiVersionsRequest with correlation id 4. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-01-23 00:23:31,075] WARN [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] Received error POLICY_VIOLATION from node 2147483646 when making an ApiVersionsRequest with correlation id 10. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-01-23 00:23:32,226] WARN [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] Received error POLICY_VIOLATION from node 2147483646 when making an ApiVersionsRequest with correlation id 15. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-01-23 00:23:32,525] ERROR [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] JoinGroup failed due to unexpected error: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-01-23 00:23:32,526] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.KafkaException: Unexpected error in join group response: Request parameters do not satisfy the configured policy.
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$JoinGroupResponseHandler.handle(AbstractCoordinator.java:711)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$JoinGroupResponseHandler.handle(AbstractCoordinator.java:603)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$CoordinatorResponseHandler.onSuccess(AbstractCoordinator.java:1270)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$CoordinatorResponseHandler.onSuccess(AbstractCoordinator.java:1245)
	at org.apache.kafka.clients.consumer.internals.RequestFuture$1.onSuccess(RequestFuture.java:206)
	at org.apache.kafka.clients.consumer.internals.RequestFuture.fireSuccess(RequestFuture.java:169)
	at org.apache.kafka.clients.consumer.internals.RequestFuture.complete(RequestFuture.java:129)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient$RequestFutureCompletionHandler.fireCompletion(ConsumerNetworkClient.java:617)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.firePendingCompletedRequests(ConsumerNetworkClient.java:427)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:312)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:251)
	at org.apache.kafka.clients.consumer.KafkaConsumer.pollForFetches(KafkaConsumer.java:1255)
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1186)
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1159)
	at kafka.tools.ConsoleConsumer$ConsumerWrapper.receive(ConsoleConsumer.scala:473)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:103)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:77)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:54)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Processed a total of 0 messages

```

</details>
      


## Check in the audit log that connection was denied

Check in the audit log that connection was denied in cluster `kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin")'
```


```json
{
  "id" : "393d0f9f-4762-42d5-a586-46db64f62166",
  "source" : "krn://cluster=jK_eyzrFRC2mLccGTfdAuw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19565"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-22T23:21:17.871299006Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin",
    "message" : "Client calls join group (group-with-aggressive-autocommit) exceed the limitation of 1 commits per minute"
  }
}
```


<details>
  <summary>Realtime command output</summary>

  ![Check in the audit log that connection was denied](images/step-36-AUDITLOG.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.LimitCommitOffsetPolicyPlugin")'
[2024-01-23 00:23:36,950] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 69 messages

```

</details>
      


## Tearing down the docker environment

Remove all your docker processes and associated volumes

* `--volumes`: Remove named volumes declared in the "volumes" section of the Compose file and anonymous volumes attached to containers.

```sh
docker compose down --volumes
```

<details>
  <summary>Realtime command output</summary>

  ![Tearing down the docker environment](images/step-37-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose down --volumes
 Container gateway1  Stopping
 Container gateway2  Stopping
 Container schema-registry  Stopping
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container schema-registry  Removed
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container kafka3  Stopping
 Container kafka1  Stopping
 Container kafka2  Stopping
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
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
      


# Conclusion

Safeguard is really a game changer!

