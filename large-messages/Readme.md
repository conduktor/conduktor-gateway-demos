# Large messages support in Kafka with built-in claimcheck pattern.



## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/ig5vu5eSCGRxheTNUBXG1kSOn.svg)](https://asciinema.org/a/ig5vu5eSCGRxheTNUBXG1kSOn)

### Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* cli-aws
* gateway1
* gateway2
* kafka1
* kafka2
* kafka3
* minio
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
  minio:
    image: quay.io/minio/minio
    hostname: minio
    environment:
      MINIO_SERVER_HOST: minio
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: minio123
      MINIO_SITE_REGION: eu-south-1
    container_name: minio
    ports:
    - 9000:9000
    command: minio server /data
  cli-aws:
    image: amazon/aws-cli
    hostname: cli-aws
    container_name: cli-aws
    entrypoint: sleep 100d
    volumes:
    - type: bind
      source: credentials
      target: /root/.aws/credentials
      read_only: true
networks:
  demo: null
```

</details>

 <details>
  <summary>docker compose ps</summary>

```
NAME              IMAGE                                    COMMAND                  SERVICE           CREATED          STATUS                    PORTS
cli-aws           amazon/aws-cli                           "sleep 100d"             cli-aws           28 seconds ago   Up 27 seconds             
gateway1          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway1          28 seconds ago   Up 16 seconds (healthy)   0.0.0.0:6969-6971->6969-6971/tcp, 0.0.0.0:8888->8888/tcp
gateway2          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway2          28 seconds ago   Up 16 seconds (healthy)   0.0.0.0:7969-7971->7969-7971/tcp, 0.0.0.0:8889->8888/tcp
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            28 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            28 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
kafka3            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka3            28 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19094->19094/tcp
minio             quay.io/minio/minio                      "/usr/bin/docker-ent…"   minio             28 seconds ago   Up 27 seconds             0.0.0.0:9000->9000/tcp
schema-registry   confluentinc/cp-schema-registry:latest   "/etc/confluent/dock…"   schema-registry   28 seconds ago   Up 16 seconds (healthy)   0.0.0.0:8081->8081/tcp
zookeeper         confluentinc/cp-zookeeper:latest         "/etc/confluent/dock…"   zookeeper         28 seconds ago   Up 27 seconds (healthy)   2181/tcp, 2888/tcp, 3888/tcp

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
 Network large-messages_default  Creating
 Network large-messages_default  Created
 Container minio  Creating
 Container cli-aws  Creating
 Container zookeeper  Creating
 Container cli-aws  Created
 Container minio  Created
 Container zookeeper  Created
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka3  Creating
 Container kafka3  Created
 Container kafka1  Created
 Container kafka2  Created
 Container gateway1  Creating
 Container schema-registry  Creating
 Container gateway2  Creating
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container minio  Starting
 Container zookeeper  Starting
 Container cli-aws  Starting
 Container minio  Started
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container cli-aws  Started
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container kafka2  Started
 Container kafka1  Started
 Container kafka3  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka3  Healthy
 Container gateway1  Started
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container schema-registry  Starting
 Container kafka1  Healthy
 Container gateway2  Starting
 Container schema-registry  Started
 Container gateway2  Started
 Container kafka1  Waiting
 Container gateway1  Waiting
 Container minio  Waiting
 Container schema-registry  Waiting
 Container zookeeper  Waiting
 Container cli-aws  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container gateway2  Waiting
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container minio  Healthy
 Container zookeeper  Healthy
 Container kafka1  Healthy
 Container cli-aws  Healthy
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
      


### Review `credentials`



```sh
cat credentials
```

<details on>
  <summary>File content</summary>

```
[minio]
aws_access_key_id = minio
aws_secret_access_key = minio123
```

</details>


## Let's create a bucket



```sh
docker compose exec cli-aws \
  aws \
    --profile minio \
    --endpoint-url=http://minio:9000 \
    --region eu-south-1 \
    s3api create-bucket \
      --bucket bucket
```

<details>
  <summary>Realtime command output</summary>

  ![Let's create a bucket](images/step-07-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose exec cli-aws \
  aws \
    --profile minio \
    --endpoint-url=http://minio:9000 \
    --region eu-south-1 \
    s3api create-bucket \
      --bucket bucket
{
    "Location": "/bucket"
}

```

</details>
      


## Creating topic `large-messages` on `teamA`

Creating topic `large-messages` on `teamA`
* Topic `large-messages` with partitions:1 and replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic large-messages
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `large-messages` on `teamA`](images/step-08-CREATE_TOPICS.gif)

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
    --topic large-messages
Created topic large-messages.

```

</details>
      


## Adding interceptor `large-messages`

Let's ask Gateway to offload large messages to S3


Creating the interceptor named `large-messages` of the plugin `io.conduktor.gateway.interceptor.LargeMessageHandlingPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.LargeMessageHandlingPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "large-messages",
    "s3Config" : {
      "accessKey" : "minio",
      "secretKey" : "minio123",
      "bucketName" : "bucket",
      "region" : "eu-south-1",
      "uri" : "http://minio:9000"
    }
  }
}
```

Here's how to send it:

```sh
cat step-09-large-messages.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/large-messages" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-09-large-messages.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `large-messages`](images/step-09-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-09-large-messages.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.LargeMessageHandlingPlugin",
  "priority": 100,
  "config": {
    "topic": "large-messages",
    "s3Config": {
      "accessKey": "minio",
      "secretKey": "minio123",
      "bucketName": "bucket",
      "region": "eu-south-1",
      "uri": "http://minio:9000"
    }
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/large-messages" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-09-large-messages.json | jq
{
  "message": "large-messages is created"
}

```

</details>
      


## Let's create a large message



```sh
openssl rand -hex $((20*1024*1024)) > large-message.bin 
ls -lh large-message.bin
```

<details>
  <summary>Realtime command output</summary>

  ![Let's create a large message](images/step-10-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

openssl rand -hex $((20*1024*1024)) > large-message.bin 
ls -lh large-message.bin
-rw-r--r--@ 1 framiere  staff    40M Jan 22 23:43 large-message.bin

```

</details>
      


## Sending large pdf file through kafka



```sh
requiredMemory=$(( 2 * $(cat large-message.bin | wc -c | awk '{print $1}')))

kafka-producer-perf-test \
  --producer.config teamA-sa.properties \
  --topic large-messages \
  --throughput -1 \
  --num-records 1 \
  --payload-file large-message.bin \
  --producer-props \
    bootstrap.servers=localhost:6969 \
    max.request.size=$requiredMemory \
    buffer.memory=$requiredMemory
```

<details>
  <summary>Realtime command output</summary>

  ![Sending large pdf file through kafka](images/step-11-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

requiredMemory=$(( 2 * $(cat large-message.bin | wc -c | awk '{print $1}')))
cat large-message.bin | wc -c | awk '{print $1}'

kafka-producer-perf-test \
  --producer.config teamA-sa.properties \
  --topic large-messages \
  --throughput -1 \
  --num-records 1 \
  --payload-file large-message.bin \
  --producer-props \
    bootstrap.servers=localhost:6969 \
    max.request.size=$requiredMemory \
    buffer.memory=$requiredMemory
Reading payloads from: /Users/framiere/conduktor/conduktor-gateway-functional-testing/target/2024.01.22-22:50:30/large-messages/large-message.bin
Number of messages read: 1
1 records sent, 0,351617 records/sec (14,06 MB/sec), 2834,00 ms avg latency, 2834,00 ms max latency, 2834 ms 50th, 2834 ms 95th, 2834 ms 99th, 2834 ms 99.9th.

```

</details>
      


## Let's read the message back



```sh
kafka-console-consumer  \
  --bootstrap-server localhost:6969 \
  --consumer.config teamA-sa.properties \
  --topic large-messages \
  --from-beginning \
  --max-messages 1 > from-kafka.bin
```

<details>
  <summary>Realtime command output</summary>

  ![Let's read the message back](images/step-12-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer  \
  --bootstrap-server localhost:6969 \
  --consumer.config teamA-sa.properties \
  --topic large-messages \
  --from-beginning \
  --property print.headers=true \
  --max-messages 1 > from-kafka.bin
Processed a total of 1 messages

```

</details>
      


## Let's compare the files



```sh
ls -lH *bin
```

<details>
  <summary>Realtime command output</summary>

  ![Let's compare the files](images/step-13-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

ls -lH *bin
-rw-r--r--@ 1 framiere  staff  41943052 Jan 22 23:43 from-kafka.bin
-rw-r--r--@ 1 framiere  staff  41943041 Jan 22 23:43 large-message.bin

```

</details>
      


## Let's look at what's inside minio



```sh
docker compose exec cli-aws \
    aws \
        --profile minio \
        --endpoint-url=http://minio:9000 \
        --region eu-south-1 \
        s3 \
        ls s3://bucket --recursive --human-readable
```

<details>
  <summary>Realtime command output</summary>

  ![Let's look at what's inside minio](images/step-14-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose exec cli-aws \
    aws \
        --profile minio \
        --endpoint-url=http://minio:9000 \
        --region eu-south-1 \
        s3 \
        ls s3://bucket --recursive --human-readable
2024-01-22 22:43:33   40.0 MiB large-messages/eaf8c224-6a8b-4432-b388-bee3b11585e4

```

</details>
      


## Consuming from `teamAlarge-messages`

Consuming from `teamAlarge-messages` in cluster `kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic teamAlarge-messages \
    --from-beginning \
    --timeout-ms 10000 \
    --property print.headers=true 
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `teamAlarge-messages`](images/step-15-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic teamAlarge-messages \
    --from-beginning \
    --timeout-ms 10000 \
    --property print.headers=true 
S3-REF-FILE-PATH:large-messages/eaf8c224-6a8b-4432-b388-bee3b11585e4	null
[2024-01-22 23:43:49,491] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

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

  ![Tearing down the docker environment](images/step-16-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose down --volumes
 Container minio  Stopping
 Container cli-aws  Stopping
 Container schema-registry  Stopping
 Container gateway1  Stopping
 Container gateway2  Stopping
 Container minio  Stopped
 Container minio  Removing
 Container minio  Removed
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka1  Stopping
 Container kafka2  Stopping
 Container kafka3  Stopping
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container cli-aws  Stopped
 Container cli-aws  Removing
 Container cli-aws  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network large-messages_default  Removing
 Network large-messages_default  Removed

```

</details>
      


# Conclusion

ksqlDB can run in a virtual cluster where all its topics are concentrated into a single physical topic

