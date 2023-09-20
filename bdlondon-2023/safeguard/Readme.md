# What is a safeguard?

Enforce your rules where it matters

Safeguard ensures that your teams follow your rules and can't break convention. 

Enable your teams, prevent common mistakes, protect your infra.

## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/Ir5AZQd9xSasE7ovV3hKO9XqN.svg)](https://asciinema.org/a/Ir5AZQd9xSasE7ovV3hKO9XqN)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcwMjk4MjQxN30.amdJi4pkJo-6OSNd0WEYmHBtXYFhxrHKzBulZX1LMdw';
bootstrap.servers=localhost:6969
```

</details>

## Creating topic `cars`

Creating topic `cars` on `teamA`
* topic `cars` with partitions:1 replication-factor:1

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

  ![Creating topic `cars`](images/step-07-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic cars.
 

```

</details>

## Producing 3messages in `cars`

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

  ![Producing 3messages in `cars`](images/step-08-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

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
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consume the `cars` topic](images/step-09-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
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
Topic: cars	PartitionCount: 1	ReplicationFactor: 1	Configs: 
	Topic: cars	Partition: 0	Leader: 1	Replicas: 1	Isr: 1
 

```

</details>

## Adding interceptor `guard-on-create-topic` in `gateway1`

Let's make sure this problem never repeats itself and add a topic creation safeguard. 

... and while we're at it, let's make sure we don't abuse partitions either


Creating the interceptor named `guard-on-create-topic` of the plugin ``io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin using the following payload

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
curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-create-topic" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin","priority":100,"config":{"replicationFactor":{"min":2,"max":2},"numPartition":{"min":1,"max":3}}}' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `guard-on-create-topic` in `gateway1`](images/step-11-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "guard-on-create-topic is created"
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

  ![Listing interceptors for `teamA`](images/step-12-LIST_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "interceptors": [
    {
      "name": "guard-on-create-topic",
      "pluginClass": "io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": null,
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

<details>
  <summary>Realtime command output</summary>

  ![Create a topic that is not within policy](images/step-13-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Error while executing topic command : Request parameters do not satisfy the configured policy. Topic 'roads' with number partitions is '100', must not be greater than 3. Topic 'roads' with replication factor is '1', must not be less than 2
 

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
Created topic roads.
 

```

</details>

## Adding interceptor `guard-on-alter-topic` in `gateway1`

Let's make sure we enforce policies when we alter topics too

Here the retention can only be between 1 and 5 days


Creating the interceptor named `guard-on-alter-topic` of the plugin ``io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin using the following payload

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
curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-alter-topic" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin","priority":100,"config":{"retentionMs":{"min":86400000,"max":432000000}}}' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `guard-on-alter-topic` in `gateway1`](images/step-15-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "guard-on-alter-topic is created"
}
 

```

</details>

## Update 'cars' with a retention of 60 days

Altering the topic is denied by our policy

## Update 'cars' with a retention of 3 days

Topic updated successfully

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --add-config retention.ms=259200000 \
    --alter \
    --topic roads
```

<details>
  <summary>Realtime command output</summary>

  ![Update 'cars' with a retention of 3 days](images/step-17-ALTER_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Adding interceptor `guard-on-produce` in `gateway1`

Let's make sure we enforce policies also at produce time!

Here message shall be sent with compression and with the right level of resiliency


Creating the interceptor named `guard-on-produce` of the plugin ``io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin using the following payload

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
curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-on-produce" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin","priority":100,"config":{"acks":{"value":[-1],"action":"BLOCK"},"compressions":{"value":["NONE","GZIP"],"action":"BLOCK"}}}' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `guard-on-produce` in `gateway1`](images/step-18-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "guard-on-produce is created"
}
 

```

</details>

## Produce sample data to our `cars` topic without the right policies

Produce 1 record ... that do not match our policy

## Produce sample data to our `cars` topic that complies with our policy

Producing a record matching our policy

```sh
echo '{"type":"Fiat","color":"red","price":-1}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --request-required-acks  -1 \
        --compression-codec  gzip \
        --topic cars
```

<details>
  <summary>Realtime command output</summary>

  ![Produce sample data to our `cars` topic that complies with our policy](images/step-20-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

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

  ![Cleanup the docker environment](images/step-21-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

# Conclusion

SQL topic is really a game changer!

