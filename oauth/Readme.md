# What is OAuth

You can be using OAuth instead of SASL_SSL

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/Qrn2HgTI93mqlLEAcm5Anuyvv.svg)](https://asciinema.org/a/Qrn2HgTI93mqlLEAcm5Anuyvv)

## Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
* kafka-client
* kafka1
* kafka2
* kafka3
* keycloack
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
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_OAUTH_JWKS_URL: http://keycloak:18080/realms/conduktor/protocol/openid-connect/certs
      GATEWAY_OAUTH_EXPECTED_ISSUER: http://keycloak:18080/realms/conduktor
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
      GATEWAY_MODE: GATEWAY_SECURITY
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_START_PORT: 7969
      GATEWAY_OAUTH_JWKS_URL: http://keycloak:18080/realms/conduktor/protocol/openid-connect/certs
      GATEWAY_OAUTH_EXPECTED_ISSUER: http://keycloak:18080/realms/conduktor
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
  keycloack:
    image: quay.io/keycloak/keycloak:22.0
    hostname: keycloak
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
    container_name: keycloak
    volumes:
    - type: bind
      source: conduktor-realm.json
      target: /opt/keycloak/data/import/realm.json
      read_only: true
    ports:
    - 18080:18080
    command:
    - start-dev
    - --http-port 18080
    - --hostname=keycloak
    - --metrics-enabled=true
    - --health-enabled=true
    - --import-realm
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
 Network oauth_default  Creating
 Network oauth_default  Created
 Container zookeeper  Creating
 Container keycloak  Creating
 Container kafka-client  Creating
 Container keycloak  Created
 Container kafka-client  Created
 Container zookeeper  Created
 Container kafka1  Creating
 Container kafka3  Creating
 Container kafka2  Creating
 Container kafka1  Created
 Container kafka3  Created
 Container kafka2  Created
 Container gateway2  Creating
 Container gateway1  Creating
 Container schema-registry  Creating
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container kafka-client  Starting
 Container zookeeper  Starting
 Container keycloak  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container keycloak  Started
 Container kafka-client  Started
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container kafka1  Started
 Container kafka2  Started
 Container kafka3  Started
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container schema-registry  Starting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway2  Starting
 Container kafka1  Healthy
 Container gateway1  Starting
 Container gateway2  Started
 Container gateway1  Started
 Container schema-registry  Started
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka-client  Waiting
 Container gateway2  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container keycloak  Waiting
 Container kafka3  Waiting
 Container zookeeper  Waiting
 Container kafka-client  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container keycloak  Healthy
 Container kafka1  Healthy
 Container zookeeper  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/hAO8eIuMShUwPR9JfS4ozOpzg.svg)](https://asciinema.org/a/hAO8eIuMShUwPR9JfS4ozOpzg)

</details>

## Review the kafka properties to connect using OAuth

Review the kafka properties to connect using OAuth

```sh
cat user-1.properties
```

<details open>
<summary>File content</summary>

```properties
sasl.mechanism=OAUTHBEARER
sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.secured.OAuthBearerLoginCallbackHandler
sasl.oauthbearer.token.endpoint.url=http://localhost:18080/realms/conduktor/protocol/openid-connect/token
sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required clientId="m2m" clientSecret="m2m" scope="email gateway";
security.protocol=SASL_PLAINTEXT
```

</details>

## Creating topic cars on gateway1

Creating on `gateway1`:

* Topic `cars` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config user-1.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
```



</details>
<details>
<summary>Output</summary>

```
[2024-04-10 02:52:37,066] WARN [Principal=:f3e0ecec-42d0-455e-88aa-5db45560c160]: Expiring credential expires at Wed Apr 10 02:53:36 GST 2024, so buffer times of 60 and 300 seconds at the front and back, respectively, cannot be accommodated.  We will refresh at Wed Apr 10 02:53:25 GST 2024. (org.apache.kafka.common.security.oauthbearer.internals.expiring.ExpiringCredentialRefreshingLogin)
Created topic cars.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/ZVBQmwoAHFhou41Ufp8db2y60.svg)](https://asciinema.org/a/ZVBQmwoAHFhou41Ufp8db2y60)

</details>

## Listing topics in gateway1



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config user-1.properties \
    --list
```



</details>
<details>
<summary>Output</summary>

```
[2024-04-10 02:52:38,664] WARN [Principal=:f3e0ecec-42d0-455e-88aa-5db45560c160]: Expiring credential expires at Wed Apr 10 02:53:38 GST 2024, so buffer times of 60 and 300 seconds at the front and back, respectively, cannot be accommodated.  We will refresh at Wed Apr 10 02:53:27 GST 2024. (org.apache.kafka.common.security.oauthbearer.internals.expiring.ExpiringCredentialRefreshingLogin)
cars

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/546lbZA7mwaLQ7PJuMocLqTtS.svg)](https://asciinema.org/a/546lbZA7mwaLQ7PJuMocLqTtS)

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
 Container keycloak  Stopping
 Container gateway2  Stopping
 Container keycloak  Stopped
 Container keycloak  Removing
 Container keycloak  Removed
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
 Network oauth_default  Removing
 Network oauth_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/pJq42slg2ufIkkSyoa4PMszwC.svg)](https://asciinema.org/a/pJq42slg2ufIkkSyoa4PMszwC)

</details>

# Conclusion

OAuth is your next security protocol!

