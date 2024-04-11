# mTLS, when SASL_SSL is not enough

When passwords are not enough, you can rely on TLS client certificate
But certificates do not host vcluster information, so let's map manually CN to vclusters.

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/xeisG3XK2U9ljtoeUjR3OMZuN.svg)](https://asciinema.org/a/xeisG3XK2U9ljtoeUjR3OMZuN)

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
      GATEWAY_MODE: GATEWAY_SECURITY
      GATEWAY_SECURITY_PROTOCOL: SSL
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_SSL_KEY_STORE_PATH: /config/keystore.jks
      GATEWAY_SSL_KEY_STORE_PASSWORD: 123456
      GATEWAY_SSL_KEY_PASSWORD: 123456
      GATEWAY_SSL_KEY_TYPE: pkcs12
      GATEWAY_SSL_TRUST_STORE_PATH: /config/truststore.jks
      GATEWAY_SSL_TRUST_STORE_PASSWORD: 123456
      GATEWAY_SSL_TRUST_STORE_TYPE: pkcs12
      GATEWAY_SSL_CLIENT_AUTH: REQUIRE
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
    volumes:
    - type: bind
      source: .
      target: /config
      read_only: true
  gateway2:
    image: conduktor/conduktor-gateway:3.0.0
    hostname: gateway2
    container_name: gateway2
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_MODE: GATEWAY_SECURITY
      GATEWAY_SECURITY_PROTOCOL: SSL
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_START_PORT: 7969
      GATEWAY_SSL_KEY_STORE_PATH: /config/keystore.jks
      GATEWAY_SSL_KEY_STORE_PASSWORD: 123456
      GATEWAY_SSL_KEY_PASSWORD: 123456
      GATEWAY_SSL_KEY_TYPE: jks
      GATEWAY_SSL_TRUST_STORE_PATH: /config/truststore.jks
      GATEWAY_SSL_TRUST_STORE_PASSWORD: 123456
      GATEWAY_SSL_TRUST_STORE_TYPE: jks
      GATEWAY_SSL_CLIENT_AUTH: REQUIRE
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
    volumes:
    - type: bind
      source: .
      target: /config
      read_only: true
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

## Generate self-signed ssl certificates



<details>
<summary>Command</summary>



```sh

rm -f *jks *key *p12 *crt

openssl req \
  -x509 \
  -newkey rsa:4096 \
  -sha256 \
  -days 3560 \
  -nodes \
  -keyout san.key \
  -out san.crt \
  -subj '/CN=username' \
  -extensions san \
  -config openssl.config

  openssl pkcs12 \
    -export \
    -in san.crt \
    -inkey san.key \
    -name brokers \
    -out san.p12 \
    -password "pass:123456"

  keytool \
    -noprompt \
    -alias brokers \
    -importkeystore \
    -deststorepass 123456 \
    -destkeystore keystore.jks \
    -srckeystore san.p12 \
    -srcstoretype PKCS12 \
    -srcstorepass 123456

  keytool \
    -noprompt \
    -import \
    -alias brokers \
    -file san.crt \
    -keypass 123456 \
    -destkeystore truststore.jks \
    -storepass 123456

echo """
bootstrap.servers=localhost:6969
security.protocol=SSL
ssl.truststore.location=$PWD/truststore.jks
ssl.truststore.password=123456
ssl.keystore.location=$PWD/keystore.jks
ssl.keystore.password=123456
""" > client.config
```



</details>
<details>
<summary>Output</summary>

```
......+...+......+.....+.......+.........+...+..+...+.+.....+.+........+++++++++++++++++++++++++++++++++++++++++++++*..+.+...........+.........+...+......+++++++++++++++++++++++++++++++++++++++++++++*.......+.....+.............+............+..+...+.........+....+..............+...+....+++++
..........+...+..........+..+......+.......+...+..+...+................+...+..+.+...+.....+......+...+..........+...........+.......+...+..+............+.+.....+.+.........+.........+..+++++++++++++++++++++++++++++++++++++++++++++*.....+.........+++++++++++++++++++++++++++++++++++++++++++++*..+...........+..........+...+..+....+.....+.+...............+.........+......+...........+...+......+.+........+......+.+............+.....+.+.........+........+...+.+...+......+.....+....+.....+.............+...+......+...+..+.+..+..................+...................+...+..+..........+...+.....+......+......+.+..+...............+.+..+...+......+......+...+..........+++++
-----
Importing keystore san.p12 to keystore.jks...
Certificate was added to keystore

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Hf4okruxLTYdpZrsCaSZqnvLo.svg)](https://asciinema.org/a/Hf4okruxLTYdpZrsCaSZqnvLo)

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
 Network ssl-and-user-mapping_default  Creating
 Network ssl-and-user-mapping_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container kafka-client  Created
 Container zookeeper  Created
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka3  Creating
 Container kafka1  Created
 Container kafka2  Created
 Container kafka3  Created
 Container gateway2  Creating
 Container gateway1  Creating
 Container schema-registry  Creating
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
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container kafka3  Started
 Container kafka2  Started
 Container kafka1  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container gateway1  Starting
 Container kafka2  Healthy
 Container gateway2  Starting
 Container kafka1  Healthy
 Container schema-registry  Starting
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
 Container kafka-client  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container zookeeper  Healthy
 Container schema-registry  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/YP59HpHrqHzd2EWMdpm1bIStB.svg)](https://asciinema.org/a/YP59HpHrqHzd2EWMdpm1bIStB)

</details>

## Adding user mapping for CN=username



<details open>
<summary>Command</summary>



```sh
cat step-06-user-mapping.json | jq

curl \
    --request POST 'http://localhost:8888/admin/userMappings/v1' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data "@step-06-user-mapping.json" | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "username": "CN=username"
}
{
  "message": "User mapping is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/DCMfXCgsH6FRZiL7Vi1O1r45k.svg)](https://asciinema.org/a/DCMfXCgsH6FRZiL7Vi1O1r45k)

</details>

## Creating topic foo on gateway1

Creating on `gateway1`:

* Topic `foo` with partitions:10 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config client.config \
    --replication-factor 1 \
    --partitions 10 \
    --create --if-not-exists \
    --topic foo
```



</details>
<details>
<summary>Output</summary>

```
Created topic foo.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/0opAiXmUqJEdWt3iYMuk1CF5q.svg)](https://asciinema.org/a/0opAiXmUqJEdWt3iYMuk1CF5q)

</details>

## Listing topics in gateway1



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config client.config \
    --list
```



</details>
<details>
<summary>Output</summary>

```
__consumer_offsets
_conduktor_gateway_acls
_conduktor_gateway_auditlogs
_conduktor_gateway_consumer_offsets
_conduktor_gateway_consumer_subscriptions
_conduktor_gateway_encryption_configs
_conduktor_gateway_interceptor_configs
_conduktor_gateway_license
_conduktor_gateway_topicmappings
_conduktor_gateway_usermappings
_schemas
foo

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/uovwFGgeUTvVttenK3IMMNJdQ.svg)](https://asciinema.org/a/uovwFGgeUTvVttenK3IMMNJdQ)

</details>

## Listing topics in kafka1



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --list
```



</details>
<details>
<summary>Output</summary>

```
__consumer_offsets
_conduktor_gateway_acls
_conduktor_gateway_auditlogs
_conduktor_gateway_consumer_offsets
_conduktor_gateway_consumer_subscriptions
_conduktor_gateway_encryption_configs
_conduktor_gateway_interceptor_configs
_conduktor_gateway_license
_conduktor_gateway_topicmappings
_conduktor_gateway_usermappings
_schemas
foo

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/3LDqXVBCWtJsltuD5nMkHkK2W.svg)](https://asciinema.org/a/3LDqXVBCWtJsltuD5nMkHkK2W)

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
 Container gateway1  Stopping
 Container gateway2  Stopping
 Container schema-registry  Stopping
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
 Container kafka2  Stopping
 Container kafka1  Stopping
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka-client  Stopped
 Container kafka-client  Removing
 Container kafka-client  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network ssl-and-user-mapping_default  Removing
 Network ssl-and-user-mapping_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/S4eimNkAnt9N4t5bZMAGcPSFi.svg)](https://asciinema.org/a/S4eimNkAnt9N4t5bZMAGcPSFi)

</details>

