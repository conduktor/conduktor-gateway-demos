# SNI Routing



## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/Oylcuha2QakuJYlq3qsOPKdNy.svg)](https://asciinema.org/a/Oylcuha2QakuJYlq3qsOPKdNy)

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
    image: harbor.cdkt.dev/conduktor/conduktor-gateway
    hostname: gateway1
    container_name: gateway1
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: gateway-sni.conduktor.local
      GATEWAY_MODE: VCLUSTER
      GATEWAY_SECURITY_PROTOCOL: SSL
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_SSL_KEY_STORE_PATH: /config/keystore.jks
      GATEWAY_SSL_KEY_STORE_PASSWORD: 123456
      GATEWAY_SSL_KEY_PASSWORD: 123456
      GATEWAY_SSL_KEY_TYPE: pkcs12
      GATEWAY_ADVERTISED_HOST_PREFIX: broker-sni-gateway1
      GATEWAY_ROUTING_MECHANISM: host
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
    networks:
      default:
        aliases:
        - broker-sni-gateway1main1.gateway-sni.conduktor.local
        - broker-sni-gateway1main2.gateway-sni.conduktor.local
        - broker-sni-gateway1main3.gateway-sni.conduktor.local
  gateway2:
    image: harbor.cdkt.dev/conduktor/conduktor-gateway
    hostname: gateway2
    container_name: gateway2
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: gateway-sni.conduktor.local
      GATEWAY_MODE: VCLUSTER
      GATEWAY_SECURITY_PROTOCOL: SSL
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_START_PORT: 7969
      GATEWAY_SSL_KEY_STORE_PATH: /config/keystore.jks
      GATEWAY_SSL_KEY_STORE_PASSWORD: 123456
      GATEWAY_SSL_KEY_PASSWORD: 123456
      GATEWAY_SSL_KEY_TYPE: jks
      GATEWAY_ADVERTISED_HOST_PREFIX: broker-sni-gateway2
      GATEWAY_ROUTING_MECHANISM: host
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
    networks:
      default:
        aliases:
        - broker-sni-gateway2main1.gateway-sni.conduktor.local
        - broker-sni-gateway2main2.gateway-sni.conduktor.local
        - broker-sni-gateway2main3.gateway-sni.conduktor.local
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

## 



<details>
<summary>Command</summary>



```sh

rm *jks *key *p12 *crt

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
security.protocol=SSL
ssl.truststore.location=/clientConfig/truststore.jks
ssl.truststore.password=123456
""" > client.config
```



</details>
<details>
<summary>Output</summary>

```
...+.......+......+........+++++++++++++++++++++++++++++++++++++++++++++*.+....+..+.+.....+.......+......+..+...+....+..+..........+.....+++++++++++++++++++++++++++++++++++++++++++++*.+....................+.............+..+.......+..+....+....................+................+...........+.......+.....+.+..+....+.....+...+.+..+...................+...+...+...+...........+.+.................+......+..........+...........+.+..................+..+....+...+.....+...+...+.......+....................+...+................+...+..+++++
....+.+...+.....+....+...+..+.+.........+...........+++++++++++++++++++++++++++++++++++++++++++++*....+..+++++++++++++++++++++++++++++++++++++++++++++*...+.............+..+...............+...+...............+.....................................+......+...............+......+......+..+.......+........+................+..+.........+.........................+......+..+..........+.....+.+.................+....+......+.....+.......+..+.+...+.....+....+..+...+............+...................+......+...+..+....+......+...........+...+....+........+.......+...+.................+..........+......+.....+.+..............+......+...+.+.....+............+..........+.....+.......+........+...............+.......+......+..+..........+..+...+........................+.+...+..+++++
-----
Importing keystore san.p12 to keystore.jks...
Certificate was added to keystore

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/QgcKGQ6oOs7pAcTXZyvYLkhm3.svg)](https://asciinema.org/a/QgcKGQ6oOs7pAcTXZyvYLkhm3)

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
 Network sni-routing_default  Creating
 Network sni-routing_default  Created
 Container kafka-client  Creating
 Container zookeeper  Creating
 Container kafka-client  Created
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
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container kafka3  Started
 Container kafka1  Started
 Container kafka2  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container gateway2  Starting
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container kafka2  Healthy
 Container gateway1  Starting
 Container schema-registry  Started
 Container gateway1  Started
 Container gateway2  Started
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container kafka2  Healthy
 Container zookeeper  Healthy
 Container kafka-client  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/iS6UjKR0GsEWdQ5Ne70Dn1Z22.svg)](https://asciinema.org/a/iS6UjKR0GsEWdQ5Ne70Dn1Z22)

</details>

## Create a topic



<details open>
<summary>Command</summary>



```sh
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server broker-sni-gateway1main1.gateway-sni.conduktor.local:6969 \
    --create \
    --replication-factor 3 \
    --partitions 1 \
    --topic clientTopic \
    --command-config /clientConfig/client.config
```



</details>
<details>
<summary>Output</summary>

```
Created topic clientTopic.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/QAqBZ7N61t0cAE4r8SK9GMbsR.svg)](https://asciinema.org/a/QAqBZ7N61t0cAE4r8SK9GMbsR)

</details>

## Produce a record to clientTopic using gateway1



<details open>
<summary>Command</summary>



```sh
echo "Hello world 1" | docker compose exec -i kafka-client \
  kafka-console-producer \
    --bootstrap-server broker-sni-gateway1main1.gateway-sni.conduktor.local:6969 \
    --topic clientTopic \
    --producer.config /clientConfig/client.config
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/fZ8SO99yixEcGd0RKEFqrMIpS.svg)](https://asciinema.org/a/fZ8SO99yixEcGd0RKEFqrMIpS)

</details>

## Produce a record to clientTopic using gateway2



<details open>
<summary>Command</summary>



```sh
echo "Hello world 2" | docker compose exec -i kafka-client \
  kafka-console-producer \
    --bootstrap-server broker-sni-gateway2main2.gateway-sni.conduktor.local:6969 \
    --topic clientTopic \
    --producer.config /clientConfig/client.config
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/NjULNM6eBP5cWBhTWKx2oAXcF.svg)](https://asciinema.org/a/NjULNM6eBP5cWBhTWKx2oAXcF)

</details>

## Consume records from clientTopic



<details open>
<summary>Command</summary>



```sh
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server broker-sni-gateway1main3.gateway-sni.conduktor.local:6969 \
    --topic clientTopic \
    --from-beginning \
    --max-messages 2 \
    --consumer.config /clientConfig/client.config
```



</details>
<details>
<summary>Output</summary>

```
Hello world 1
Hello world 2
Processed a total of 2 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/IXSbmgcAzqn2xC7L8nvIQSHIi.svg)](https://asciinema.org/a/IXSbmgcAzqn2xC7L8nvIQSHIi)

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
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka3  Stopping
 Container kafka1  Stopping
 Container kafka2  Stopping
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
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
 Network sni-routing_default  Removing
 Network sni-routing_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/JjRSdTg0s268sBOYjtLdjTnM4.svg)](https://asciinema.org/a/JjRSdTg0s268sBOYjtLdjTnM4)

</details>

