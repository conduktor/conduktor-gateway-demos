# a ksqlDB experience on concentrated topics



## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/J6nnXytlKmFXsjXqDNay4T03Q.svg)](https://asciinema.org/a/J6nnXytlKmFXsjXqDNay4T03Q)

### Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
* kafka1
* kafka2
* kafka3
* ksqldb-server
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
  ksqldb-server:
    image: confluentinc/cp-ksqldb-server:7.4.3.arm64
    healthcheck:
      test: curl localhost:8088/info | grep RUNNING
      interval: 5s
      retries: 25
    hostname: ksqldb-server
    environment:
      KSQL_LISTENERS: http://0.0.0.0:8088
      KSQL_BOOTSTRAP_SERVERS: ${KSQL_BOOTSTRAP_SERVERS:-}
      KSQL_SECURITY_PROTOCOL: ${KSQL_SECURITY_PROTOCOL:-}
      KSQL_SASL_MECHANISM: ${KSQL_SASL_MECHANISM:-}
      KSQL_SASL_JAAS_CONFIG: ${KSQL_SASL_JAAS_CONFIG:-}
      KSQL_KSQL_STREAMS_PROCESSING_GUARANTEE: exactly_once_v2
      KSQL_KSQL_LOGGING_PROCESSING_STREAM_AUTO_CREATE: 'true'
      KSQL_KSQL_LOGGING_PROCESSING_TOPIC_AUTO_CREATE: 'true'
    depends_on:
      kafka1:
        condition: service_healthy
      kafka2:
        condition: service_healthy
      kafka3:
        condition: service_healthy
    container_name: ksqldb-server
    network_mode: host
    profiles:
    - ksqldb
    volumes:
    - type: bind
      source: .
      target: /sql
      read_only: true
    ports:
    - 8088:8088
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
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            33 seconds ago   Up 26 seconds (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            33 seconds ago   Up 26 seconds (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
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
 Network ksqldb_default  Creating
 Network ksqldb_default  Created
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
 Container kafka2  Started
 Container kafka3  Started
 Container kafka1  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container gateway2  Starting
 Container kafka3  Healthy
 Container schema-registry  Starting
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container gateway1  Starting
 Container schema-registry  Started
 Container gateway2  Started
 Container gateway1  Started
 Container gateway2  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container zookeeper  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
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
      


## 

Let's tell `gateway1` that topics matching the pattern `.*` need to be concentrated into the underlying `concentrated` physical topic.

> [!NOTE]
> You don’t need to create the physical topic that backs the concentrated topics, it will automatically be created when a client topic starts using the concentrated topic.

```sh
cat step-06-mapping.json | jq

curl \
    --request POST 'http://localhost:8888/admin/vclusters/v1/vcluster/teamA/topics/.%2A' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data "@step-06-mapping.json" | jq
```

<details>
  <summary>Realtime command output</summary>

  ![](images/step-06-CREATE_CONCENTRATED_TOPIC.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-06-mapping.json | jq
{
  "concentrated": true,
  "readOnly": false,
  "physicalTopicName": "concentrated"
}

curl \
    --request POST 'http://localhost:8888/admin/vclusters/v1/vcluster/teamA/topics/.%2A' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data "@step-06-mapping.json" | jq
{
  "logicalTopicName": ".*",
  "physicalTopicName": "concentrated",
  "readOnly": false,
  "concentrated": true
}

```

</details>
      


## Start ksqlDB



```sh
export KSQL_BOOTSTRAP_SERVERS="localhost:6969"
export KSQL_SECURITY_PROTOCOL="SASL_PLAINTEXT"
export KSQL_SASL_MECHANISM="PLAIN"
export KSQL_SASL_JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzczODk5NX0.WHXG_DPBRBce90-s8vIy4E6fnMNHzk1ERbAVD3qpxaA';"
docker compose --profile ksqldb up -d --wait
```

<details>
  <summary>Realtime command output</summary>

  ![Start ksqlDB](images/step-07-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

export KSQL_BOOTSTRAP_SERVERS="localhost:6969"
export KSQL_SECURITY_PROTOCOL="SASL_PLAINTEXT"
export KSQL_SASL_MECHANISM="PLAIN"
export KSQL_SASL_JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzczODk5NX0.WHXG_DPBRBce90-s8vIy4E6fnMNHzk1ERbAVD3qpxaA';"
docker compose --profile ksqldb up -d --wait
 Container zookeeper  Running
 Container kafka1  Running
 Container kafka2  Running
 Container kafka3  Running
 Container schema-registry  Running
 Container gateway2  Running
 Container ksqldb-server  Creating
 Container gateway1  Running
 ksqldb-server Published ports are discarded when using host network mode 
 Container ksqldb-server  Created
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container zookeeper  Healthy
 Container zookeeper  Healthy
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container ksqldb-server  Starting
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container ksqldb-server  Started
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container ksqldb-server  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway1  Healthy
 Container kafka3  Healthy
 Container gateway2  Healthy
 Container schema-registry  Healthy
 Container ksqldb-server  Healthy

```

</details>
      


## Listing topics in `teamA`



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `teamA`](images/step-08-LIST_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
_confluent-ksql-default__command_topic
default_ksql_processing_log

```

</details>
      


## Listing topics in `kafka1`



```sh
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `kafka1`](images/step-09-LIST_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --list
__consumer_offsets
__transaction_state
_acls
_auditLogs
_consumerGroupSubscriptionBackingTopic
_encryptionConfig
_interceptorConfigs
_license
_offsetStore
_schemas
_topicMappings
_topicRegistry
_userMapping
concentrated

```

</details>
      


### Review `ksql.sql`



```sh
cat ksql.sql
```

<details>
  <summary>File content</summary>

```sql
SET 'processing.guarantee' = 'exactly_once_v2';

CREATE STREAM riderLocations (profileId VARCHAR, latitude DOUBLE, longitude DOUBLE)
  WITH (kafka_topic='locations', value_format='json', partitions=1);

CREATE TABLE currentLocation AS
  SELECT profileId,
         LATEST_BY_OFFSET(latitude) AS la,
         LATEST_BY_OFFSET(longitude) AS lo
  FROM riderlocations
  GROUP BY profileId
  EMIT CHANGES;

CREATE TABLE ridersNearMountainView AS
  SELECT ROUND(GEO_DISTANCE(la, lo, 37.4133, -122.1162), -1) AS distanceInMiles,
         COLLECT_LIST(profileId) AS riders,
         COUNT(*) AS count
  FROM currentLocation
  GROUP BY ROUND(GEO_DISTANCE(la, lo, 37.4133, -122.1162), -1);

INSERT INTO riderLocations (profileId, latitude, longitude) VALUES ('c2309eec', 37.7877, -122.4205);
INSERT INTO riderLocations (profileId, latitude, longitude) VALUES ('18f4ea86', 37.3903, -122.0643);
INSERT INTO riderLocations (profileId, latitude, longitude) VALUES ('4ab5cbad', 37.3952, -122.0813);
INSERT INTO riderLocations (profileId, latitude, longitude) VALUES ('8b6eae59', 37.3944, -122.0813);
INSERT INTO riderLocations (profileId, latitude, longitude) VALUES ('4a7c7b41', 37.4049, -122.0822);
INSERT INTO riderLocations (profileId, latitude, longitude) VALUES ('4ddad000', 37.7857, -122.4011);
```

</details>


## 



```sh
docker exec ksqldb-server ksql 'http://localhost:8088' -f /sql/ksql.sql
```

<details>
  <summary>Realtime command output</summary>

  ![](images/step-11-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker exec ksqldb-server ksql 'http://localhost:8088' -f /sql/ksql.sql
Jan 22, 2024 10:37:55 PM org.jline.utils.Log logr
WARNING: Unable to create a system terminal, creating a dumb terminal (enable debug logging for more information)
Successfully changed local property 'processing.guarantee' to 'exactly_once_v2'. Use the UNSET command to revert your change.

CREATE STREAM RIDERLOCATIONS (PROFILEID STRING, LATITUDE DOUBLE, LONGITUDE DOUBLE) WITH (CLEANUP_POLICY='delete', KAFKA_TOPIC='locations', KEY_FORMAT='KAFKA', PARTITIONS=1, VALUE_FORMAT='JSON');
 Message        

 Stream created 


CREATE TABLE CURRENTLOCATION WITH (CLEANUP_POLICY='compact', KAFKA_TOPIC='CURRENTLOCATION', PARTITIONS=1, REPLICAS=1, RETENTION_MS=604800000) AS SELECT
  RIDERLOCATIONS.PROFILEID PROFILEID,
  LATEST_BY_OFFSET(RIDERLOCATIONS.LATITUDE) LA,
  LATEST_BY_OFFSET(RIDERLOCATIONS.LONGITUDE) LO
FROM RIDERLOCATIONS RIDERLOCATIONS
GROUP BY RIDERLOCATIONS.PROFILEID
EMIT CHANGES;
 Message                                      

 Created query with ID CTAS_CURRENTLOCATION_3 


CREATE TABLE RIDERSNEARMOUNTAINVIEW WITH (CLEANUP_POLICY='compact', KAFKA_TOPIC='RIDERSNEARMOUNTAINVIEW', PARTITIONS=1, REPLICAS=1, RETENTION_MS=604800000) AS SELECT
  ROUND(GEO_DISTANCE(CURRENTLOCATION.LA, CURRENTLOCATION.LO, 37.4133, -122.1162), -1) DISTANCEINMILES,
  COLLECT_LIST(CURRENTLOCATION.PROFILEID) RIDERS,
  COUNT(*) COUNT
FROM CURRENTLOCATION CURRENTLOCATION
GROUP BY ROUND(GEO_DISTANCE(CURRENTLOCATION.LA, CURRENTLOCATION.LO, 37.4133, -122.1162), -1)
EMIT CHANGES;
 Message                                             

 Created query with ID CTAS_RIDERSNEARMOUNTAINVIEW_5 


```

</details>
      


## Listing topics in `teamA`



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `teamA`](images/step-12-LIST_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
CURRENTLOCATION
RIDERSNEARMOUNTAINVIEW
_confluent-ksql-default__command_topic
_confluent-ksql-default_query_CTAS_CURRENTLOCATION_3-Aggregate-Aggregate-Materialize-changelog
_confluent-ksql-default_query_CTAS_CURRENTLOCATION_3-Aggregate-GroupBy-repartition
_confluent-ksql-default_query_CTAS_RIDERSNEARMOUNTAINVIEW_5-Aggregate-Aggregate-Materialize-changelog
_confluent-ksql-default_query_CTAS_RIDERSNEARMOUNTAINVIEW_5-Aggregate-GroupBy-repartition
_confluent-ksql-default_query_CTAS_RIDERSNEARMOUNTAINVIEW_5-KsqlTopic-Reduce-changelog
default_ksql_processing_log
locations

```

</details>
      


## Listing topics in `kafka1`



```sh
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![Listing topics in `kafka1`](images/step-13-LIST_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --list
__consumer_offsets
__transaction_state
_acls
_auditLogs
_consumerGroupSubscriptionBackingTopic
_encryptionConfig
_interceptorConfigs
_license
_offsetStore
_schemas
_topicMappings
_topicRegistry
_userMapping
concentrated
concentrated_compacted

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

  ![Tearing down the docker environment](images/step-14-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose down --volumes
 Container gateway2  Stopping
 Container gateway1  Stopping
 Container schema-registry  Stopping
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway2  Removed
 Container gateway1  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka3  Stopping
 Container kafka1  Stopping
 Container kafka2  Stopping
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network ksqldb_default  Removing
 Network ksqldb_default  Removed

```

</details>
      


# Conclusion

ksqlDB can run in a virtual cluster where all its topics are concentrated into a single physical topic

