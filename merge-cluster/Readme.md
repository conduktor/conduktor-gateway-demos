# What is merge cluster?

Conduktor Gateway's merge cluster brings all your Kafka clusters together into an instance for clients to access.

## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/wpPq6peWQWowZnuVdaoslbj4v.svg)](https://asciinema.org/a/wpPq6peWQWowZnuVdaoslbj4v)

### Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
* kafka1
* kafka2
* kafka3
* s1_kafka1
* s1_kafka2
* s1_kafka3
* schema-registry
* zookeeper
* zookeeper_s1

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
      GATEWAY_BACKEND_KAFKA_SELECTOR: 'file : { path:  /config/clusters.yaml}'
      GATEWAY_PORT_COUNT: 6
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
    - 6972:6972
    - 6973:6973
    - 6974:6974
    healthcheck:
      test: curl localhost:8888/health
      interval: 5s
      retries: 25
    volumes:
    - type: bind
      source: .
      target: /config
      read_only: true
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
      GATEWAY_BACKEND_KAFKA_SELECTOR: 'file : { path:  /config/clusters.yaml}'
      GATEWAY_PORT_COUNT: 6
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
    - 7972:7972
    - 7973:7973
    - 7974:7974
    healthcheck:
      test: curl localhost:8888/health
      interval: 5s
      retries: 25
    volumes:
    - type: bind
      source: .
      target: /config
      read_only: true
  zookeeper_s1:
    image: confluentinc/cp-zookeeper:latest
    healthcheck:
      test: nc -zv 0.0.0.0 12801 || exit 1
      interval: 5s
      retries: 25
    hostname: zookeeper_s1
    environment:
      ZOOKEEPER_CLIENT_PORT: 12801
      ZOOKEEPER_TICK_TIME: 2000
    container_name: zookeeper_s1
    ports:
    - 12801:12801
  s1_kafka1:
    image: confluentinc/cp-kafka:latest
    healthcheck:
      test: nc -zv s1_kafka1 9092 || exit 1
      interval: 5s
      retries: 25
    hostname: s1_kafka1
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper_s1:12801
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:29092,INTERNAL://:9092
      KAFKA_ADVERTISED_LISTENERS: EXTERNAL_SAME_HOST://localhost:29092,INTERNAL://s1_kafka1:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper_s1:
        condition: service_healthy
    container_name: s1_kafka1
    ports:
    - 29092:29092
  s1_kafka2:
    image: confluentinc/cp-kafka:latest
    healthcheck:
      test: nc -zv s1_kafka2 9093 || exit 1
      interval: 5s
      retries: 25
    hostname: s1_kafka2
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_ZOOKEEPER_CONNECT: zookeeper_s1:12801
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:29093,INTERNAL://:9093
      KAFKA_ADVERTISED_LISTENERS: EXTERNAL_SAME_HOST://localhost:29093,INTERNAL://s1_kafka2:9093
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper_s1:
        condition: service_healthy
    container_name: s1_kafka2
    ports:
    - 29093:29093
  s1_kafka3:
    image: confluentinc/cp-kafka:latest
    healthcheck:
      test: nc -zv s1_kafka3 9094 || exit 1
      interval: 5s
      retries: 25
    hostname: s1_kafka3
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_ZOOKEEPER_CONNECT: zookeeper_s1:12801
      KAFKA_LISTENERS: EXTERNAL_SAME_HOST://:29094,INTERNAL://:9094
      KAFKA_ADVERTISED_LISTENERS: EXTERNAL_SAME_HOST://localhost:29094,INTERNAL://s1_kafka3:9094
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper_s1:
        condition: service_healthy
    container_name: s1_kafka3
    ports:
    - 29094:29094
networks:
  demo: null
```

</details>

 <details>
  <summary>docker compose ps</summary>

```
NAME              IMAGE                                    COMMAND                  SERVICE           CREATED          STATUS                    PORTS
gateway1          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway1          38 seconds ago   Up 21 seconds (healthy)   0.0.0.0:6969-6974->6969-6974/tcp, 0.0.0.0:8888->8888/tcp
gateway2          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway2          38 seconds ago   Up 21 seconds (healthy)   0.0.0.0:7969-7974->7969-7974/tcp, 0.0.0.0:8889->8888/tcp
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            38 seconds ago   Up 31 seconds (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            38 seconds ago   Up 31 seconds (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
kafka3            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka3            38 seconds ago   Up 31 seconds (healthy)   9092/tcp, 0.0.0.0:19094->19094/tcp
s1_kafka1         confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   s1_kafka1         38 seconds ago   Up 31 seconds (healthy)   9092/tcp, 0.0.0.0:29092->29092/tcp
s1_kafka2         confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   s1_kafka2         38 seconds ago   Up 31 seconds (healthy)   9092/tcp, 0.0.0.0:29093->29093/tcp
s1_kafka3         confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   s1_kafka3         38 seconds ago   Up 31 seconds (healthy)   9092/tcp, 0.0.0.0:29094->29094/tcp
schema-registry   confluentinc/cp-schema-registry:latest   "/etc/confluent/dock…"   schema-registry   38 seconds ago   Up 21 seconds (healthy)   0.0.0.0:8081->8081/tcp
zookeeper         confluentinc/cp-zookeeper:latest         "/etc/confluent/dock…"   zookeeper         38 seconds ago   Up 37 seconds (healthy)   2181/tcp, 2888/tcp, 3888/tcp
zookeeper_s1      confluentinc/cp-zookeeper:latest         "/etc/confluent/dock…"   zookeeper_s1      38 seconds ago   Up 37 seconds (healthy)   2181/tcp, 2888/tcp, 3888/tcp, 0.0.0.0:12801->12801/tcp

```

</details>

### Review the Gateway configuration

Review the Gateway configuration

```sh
cat clusters.yaml
```

<details on>
  <summary>File content</summary>

```yaml
config:
  main:
    bootstrap.servers: kafka1:9092,kafka2:9093,kafka3:9094

  cluster1:
    bootstrap.servers: s1_kafka1:9092,s1_kafka2:9093,s1_kafka3:9094
    gateway.roles: upstream
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

  ![Starting the docker environment](images/step-05-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose up --detach --wait
 Network merge-cluster_default  Creating
 Network merge-cluster_default  Created
 Container zookeeper  Creating
 Container zookeeper_s1  Creating
 Container zookeeper_s1  Created
 Container s1_kafka1  Creating
 Container s1_kafka3  Creating
 Container s1_kafka2  Creating
 Container zookeeper  Created
 Container kafka1  Creating
 Container kafka2  Creating
 Container kafka3  Creating
 Container kafka3  Created
 Container s1_kafka1  Created
 Container kafka2  Created
 Container kafka1  Created
 Container schema-registry  Creating
 Container gateway1  Creating
 Container gateway2  Creating
 Container s1_kafka2  Created
 Container s1_kafka3  Created
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container zookeeper_s1  Starting
 Container zookeeper  Starting
 Container zookeeper_s1  Started
 Container zookeeper_s1  Waiting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper_s1  Waiting
 Container zookeeper_s1  Waiting
 Container zookeeper_s1  Healthy
 Container s1_kafka3  Starting
 Container zookeeper_s1  Healthy
 Container s1_kafka2  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper_s1  Healthy
 Container s1_kafka1  Starting
 Container s1_kafka3  Started
 Container kafka2  Started
 Container s1_kafka2  Started
 Container kafka1  Started
 Container s1_kafka1  Started
 Container kafka3  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container gateway1  Starting
 Container kafka3  Healthy
 Container schema-registry  Starting
 Container kafka3  Healthy
 Container gateway2  Starting
 Container schema-registry  Started
 Container gateway2  Started
 Container gateway1  Started
 Container schema-registry  Waiting
 Container zookeeper  Waiting
 Container gateway1  Waiting
 Container zookeeper_s1  Waiting
 Container s1_kafka1  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container gateway2  Waiting
 Container s1_kafka3  Waiting
 Container kafka2  Waiting
 Container s1_kafka2  Waiting
 Container s1_kafka2  Healthy
 Container kafka2  Healthy
 Container s1_kafka3  Healthy
 Container s1_kafka1  Healthy
 Container kafka3  Healthy
 Container zookeeper  Healthy
 Container kafka1  Healthy
 Container zookeeper_s1  Healthy
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

  ![Creating virtual cluster `teamA`](images/step-06-CREATE_VIRTUAL_CLUSTER.gif)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzc0MDI1MX0.YQUIMIf1Fv9JwSpvZn33qhPwHbrwc1VgD13WN6HCAi0';
bootstrap.servers=localhost:6969
```

</details>


## Create the topic 'cars' in main cluster

Creating topic `cars` on `kafka1`
* Topic `cars` with partitions:1 and replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
```

<details>
  <summary>Realtime command output</summary>

  ![Create the topic 'cars' in main cluster](images/step-08-CREATE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
Created topic cars.

```

</details>
      


## Create the topic 'cars' in cluster1

Creating topic `cars` on `s1_kafka1`
* Topic `cars` with partitions:1 and replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
```

<details>
  <summary>Realtime command output</summary>

  ![Create the topic 'cars' in cluster1](images/step-09-CREATE_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
Created topic cars.

```

</details>
      


## Let's route the topic 'eu_cars', as seen by the client application, on to the 'cars' topic on the main (default) cluster



```sh
curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/topicMappings/teamA/eu_cars \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "clusterId": "main",
      "topicName": "cars",
      "concentrated": false
    }' | jq

curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/topics/teamA \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "name": "eu_cars"
    }' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Let's route the topic 'eu_cars', as seen by the client application, on to the 'cars' topic on the main (default) cluster](images/step-10-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/topicMappings/teamA/eu_cars \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "clusterId": "main",
      "topicName": "cars",
      "concentrated": false
    }' | jq
{
  "message": "cars is created"
}

curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/topics/teamA \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "name": "eu_cars"
    }' | jq
{
  "message": "eu_cars is created"
}

```

</details>
      


## Let's route the topic 'us_cars', as seen by the client application, on to the 'cars' topic on the second cluster (cluster1)



```sh
curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/topicMappings/teamA/us_cars \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "clusterId": "cluster1",
      "topicName": "cars",
      "concentrated": false
    }' | jq

curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/topics/teamA \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "name": "us_cars"
    }' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Let's route the topic 'us_cars', as seen by the client application, on to the 'cars' topic on the second cluster (cluster1)](images/step-11-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/topicMappings/teamA/us_cars \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "clusterId": "cluster1",
      "topicName": "cars",
      "concentrated": false
    }' | jq
{
  "message": "cars is created"
}

curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/topics/teamA \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "name": "us_cars"
    }' | jq
{
  "message": "us_cars is created"
}

```

</details>
      


## Send into topic 'eu_cars'

Producing 1 message in `eu_cars` in cluster `teamA`

```sh
echo '{"name":"eu_cars_record"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic eu_cars
```

<details>
  <summary>Realtime command output</summary>

  ![Send into topic 'eu_cars'](images/step-12-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"name":"eu_cars_record"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic eu_cars

```

</details>
      


## Send into topic 'us_cars'

Producing 1 message in `us_cars` in cluster `teamA`

```sh
echo '{"name":"us_cars_record"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic us_cars
```

<details>
  <summary>Realtime command output</summary>

  ![Send into topic 'us_cars'](images/step-13-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"name":"us_cars_record"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic us_cars

```

</details>
      


## Consuming from `eu_cars`

Consuming from `eu_cars` in cluster `teamA`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic eu_cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `eu_cars`](images/step-14-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic eu_cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 23:59:05,991] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "name": "eu_cars_record"
}

```

</details>
      


## Consuming from `us_cars`

Consuming from `us_cars` in cluster `teamA`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic us_cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Consuming from `us_cars`](images/step-15-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic us_cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 23:59:17,957] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "name": "us_cars_record"
}

```

</details>
      


## Verify `eu_cars_record` is not in main kafka

Verify `eu_cars_record` is not in main kafka in cluster `kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Verify `eu_cars_record` is not in main kafka](images/step-16-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 23:59:29,738] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "name": "eu_cars_record"
}

```

</details>
      


## Verify `us_cars_record` is not in cluster1 kafka

Verify `us_cars_record` is not in cluster1 kafka in cluster `s1_kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Verify `us_cars_record` is not in cluster1 kafka](images/step-17-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 23:59:42,375] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "name": "us_cars_record"
}

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

  ![Tearing down the docker environment](images/step-18-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose down --volumes
 Container gateway1  Stopping
 Container schema-registry  Stopping
 Container s1_kafka1  Stopping
 Container s1_kafka3  Stopping
 Container s1_kafka2  Stopping
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
 Container kafka3  Stopping
 Container kafka1  Stopping
 Container kafka2  Stopping
 Container s1_kafka1  Stopped
 Container s1_kafka1  Removing
 Container s1_kafka1  Removed
 Container s1_kafka3  Stopped
 Container s1_kafka3  Removing
 Container s1_kafka3  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container s1_kafka2  Stopped
 Container s1_kafka2  Removing
 Container s1_kafka2  Removed
 Container zookeeper_s1  Stopping
 Container zookeeper_s1  Stopped
 Container zookeeper_s1  Removing
 Container zookeeper_s1  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network merge-cluster_default  Removing
 Network merge-cluster_default  Removed

```

</details>
      


# Conclusion

Merge cluster is simple as it

