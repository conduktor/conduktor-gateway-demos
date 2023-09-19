# A full field level crypto shredding walkthrough



## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/8WSFYuzP6tXYrcBUEqlUATsLi.svg)](https://asciinema.org/a/8WSFYuzP6tXYrcBUEqlUATsLi)

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
    hostname: gateway1
    container_name: gateway1
    image: conduktor/conduktor-gateway:2.1.4
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
      GATEWAY_SECURITY_PROVIDER: BOUNCY_CASTLE
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
    hostname: gateway2
    container_name: gateway2
    image: conduktor/conduktor-gateway:2.1.4
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_START_PORT: 7969
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
      GATEWAY_SECURITY_PROVIDER: BOUNCY_CASTLE
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
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
  vault:
    image: hashicorp/vault
    healthcheck:
      test: nc -zv 0.0.0.0 8200
      interval: 5s
      retries: 25
    hostname: vault
    environment:
      VAULT_ADDR: http://0.0.0.0:8200
      VAULT_DEV_ROOT_TOKEN_ID: vault-plaintext-root-token
    container_name: vault
    ports:
    - 8200:8200
    command:
    - sh
    - -c
    - (while ! nc -z 127.0.0.1 8200; do sleep 1; echo 'waiting for vault service ...';
      done; export VAULT_ADDR='http://0.0.0.0:8200';vault secrets enable transit;
      vault secrets enable -version=1 kv; vault secrets enable totp ) & vault server
      -dev -dev-listen-address=0.0.0.0:8200
networks:
  demo: null
```

</details>

## Start the docker environment

Start your docker environment

```sh
docker compose up -d --wait
```

<details>
  <summary>Realtime command output</summary>

  ![Start the docker environment](images/step-04-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ docker compose up -d --wait
 Network crypto-shredding-bouncy-castle_default  Creating
 Network crypto-shredding-bouncy-castle_default  Created
 Container zookeeper  Creating
 Container cli-kcat  Creating
 Container vault  Creating
 Container vault  Created
 Container cli-kcat  Created
 Container zookeeper  Created
 Container kafka1  Creating
 Container kafka2  Creating
 Container kafka3  Creating
 Container kafka2  Created
 Container kafka3  Created
 Container kafka1  Created
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Creating
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway2  Created
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway1  Created
 Container schema-registry  Created
 Container cli-kcat  Starting
 Container vault  Starting
 Container zookeeper  Starting
 Container cli-kcat  Started
 Container vault  Started
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container kafka3  Started
 Container kafka2  Started
 Container kafka1  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container gateway2  Starting
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container gateway1  Starting
 Container kafka1  Healthy
 Container schema-registry  Starting
 Container schema-registry  Started
 Container gateway1  Started
 Container gateway2  Started
 Container gateway1  Waiting
 Container kafka1  Waiting
 Container zookeeper  Waiting
 Container kafka3  Waiting
 Container cli-kcat  Waiting
 Container vault  Waiting
 Container kafka2  Waiting
 Container gateway2  Waiting
 Container schema-registry  Waiting
 Container cli-kcat  Healthy
 Container zookeeper  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container vault  Healthy
 Container kafka3  Healthy
 Container schema-registry  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy

```

</details>

## Verify the security provider setup



```sh
docker logs  gateway1 2>&1  | grep "Security Provider"
```

<details>
  <summary>Realtime command output</summary>

  ![Verify the security provider setup](images/step-05-SH.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ docker logs gateway1
+ grep 'Security Provider'
2023-09-19T10:27:15.560+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:213[m] - Enabling Bouncy Castle as Security Provider
2023-09-19T10:27:15.611+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider BCJSSE at position 0
2023-09-19T10:27:15.611+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SUN at position 1
2023-09-19T10:27:15.614+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunRsaSign at position 2
2023-09-19T10:27:15.614+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunEC at position 3
2023-09-19T10:27:15.614+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunJSSE at position 4
2023-09-19T10:27:15.615+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunJCE at position 5
2023-09-19T10:27:15.617+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunJGSS at position 6
2023-09-19T10:27:15.617+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunSASL at position 7
2023-09-19T10:27:15.618+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider XMLDSig at position 8
2023-09-19T10:27:15.618+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunPCSC at position 9
2023-09-19T10:27:15.618+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider JdkLDAP at position 10
2023-09-19T10:27:15.619+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider JdkSASL at position 11
2023-09-19T10:27:15.619+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunPKCS11 at position 12

```

</details>

## Verify the disabled algorithms



```sh
docker logs  gateway1 2>&1  | grep "disabledAlgorithms"
```

<details>
  <summary>Realtime command output</summary>

  ![Verify the disabled algorithms](images/step-06-SH.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ docker logs gateway1
+ grep disabledAlgorithms
INFO: Found string security property [jdk.tls.disabledAlgorithms]: SSLv3, TLSv1, TLSv1.1, RC4, DES, MD5withRSA, DH keySize < 1024, EC keySize < 224, 3DES_EDE_CBC, anon, NULL
INFO: Found string security property [jdk.certpath.disabledAlgorithms]: MD2, MD5, SHA1 jdkCA step-06-SH-OUTPUT usage TLSServer, RSA keySize < 1024, DSA keySize < 1024, EC keySize < 224
WARNING: Ignoring unsupported entry in 'jdk.certpath.disabledAlgorithms': SHA1 jdkCA step-06-SH-OUTPUT usage TLSServer

```

</details>

## Let's create the virtual cluster `teamA`



```sh
token=$(curl \
    --silent \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa" \
    --user 'admin:conduktor' \
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

  ![Let's create the virtual cluster `teamA`](images/step-07-CREATE_VIRTUAL_CLUSTERS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
++ curl --silent --request POST http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa --user admin:conduktor --header 'Content-Type: application/json' --data-raw '{"lifeTimeSeconds": 7776000}'
++ jq -r .token
+ token=eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcwMjg5NTI1NH0.FRPNmiN9mqnBsAQzogK0NQgZOf8Dnq0tAXwK4KtI0x8
+ echo '
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='\''sa'\'' password='\''eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcwMjg5NTI1NH0.FRPNmiN9mqnBsAQzogK0NQgZOf8Dnq0tAXwK4KtI0x8'\'';
'

```

</details>

## Create the `customer-shredding` topic



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic customers-shredding
```

<details>
  <summary>Realtime command output</summary>

  ![Create the `customer-shredding` topic](images/step-08-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-topics --bootstrap-server localhost:6969 --command-config teamA-sa.properties --replication-factor 1 --partitions 1 --create --if-not-exists --topic customers-shredding
Created topic customers-shredding.

```

</details>

## List topics



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
```

<details>
  <summary>Realtime command output</summary>

  ![List topics](images/step-09-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-topics --bootstrap-server localhost:6969 --command-config teamA-sa.properties --list
customers-shredding

```

</details>

## Let's ask gateway to encrypt messages using vault and dynamic keys




Creating the interceptor named `crypto-shredding-encrypt` of the plugin `io.conduktor.gateway.interceptor.EncryptPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.EncryptPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "customers-shredding",
    "kmsConfig" : {
      "vault" : {
        "uri" : "http://vault:8200",
        "token" : "vault-plaintext-root-token",
        "version" : 1
      }
    },
    "fields" : [ {
      "fieldName" : "password",
      "keySecretId" : "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
      "algorithm" : {
        "type" : "AES_GCM",
        "kms" : "VAULT"
      }
    }, {
      "fieldName" : "visa",
      "keySecretId" : "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
      "algorithm" : {
        "type" : "AES_GCM",
        "kms" : "VAULT"
      }
    } ]
  }
}
```

Here's how to send it:

```sh
curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-encrypt" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.EncryptPlugin","priority":100,"config":{"topic":"customers-shredding","kmsConfig":{"vault":{"uri":"http://vault:8200","token":"vault-plaintext-root-token","version":1}},"fields":[{"fieldName":"password","keySecretId":"vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}","algorithm":{"type":"AES_GCM","kms":"VAULT"}},{"fieldName":"visa","keySecretId":"vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}","algorithm":{"type":"AES_GCM","kms":"VAULT"}}]}}' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Let's ask gateway to encrypt messages using vault and dynamic keys](images/step-10-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ curl --silent --request POST http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-encrypt --user admin:conduktor --header 'Content-Type: application/json' --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.EncryptPlugin","priority":100,"config":{"topic":"customers-shredding","kmsConfig":{"vault":{"uri":"http://vault:8200","token":"vault-plaintext-root-token","version":1}},"fields":[{"fieldName":"password","keySecretId":"vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}","algorithm":{"type":"AES_GCM","kms":"VAULT"}},{"fieldName":"visa","keySecretId":"vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}","algorithm":{"type":"AES_GCM","kms":"VAULT"}}]}}'
+ jq
{
  "message": "crypto-shredding-encrypt is created"
}

```

</details>

## List gateway interceptors



```sh
curl \
    -u "admin:conduktor" \
    --request GET "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptors" \
    --header 'Content-Type: application/json' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![List gateway interceptors](images/step-11-LIST_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ curl -u admin:conduktor --request GET http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptors --header 'Content-Type: application/json'
+ jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0100   620  100   620    0     0  13626      0 --:--:-- --:--:-- --:--:-- 15121
{
  "interceptors": [
    {
      "name": "crypto-shredding-encrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": null,
      "config": {
        "topic": "customers-shredding",
        "kmsConfig": {
          "vault": {
            "uri": "http://vault:8200",
            "token": "vault-plaintext-root-token",
            "version": 1
          }
        },
        "fields": [
          {
            "fieldName": "password",
            "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
            "algorithm": {
              "type": "AES_GCM",
              "kms": "VAULT"
            }
          },
          {
            "fieldName": "visa",
            "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
            "algorithm": {
              "type": "AES_GCM",
              "kms": "VAULT"
            }
          }
        ]
      }
    }
  ]
}

```

</details>

## Let's produce sample data for `tom` and `florent`



```sh
echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers-shredding

echo '{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers-shredding
```

<details>
  <summary>Realtime command output</summary>

  ![Let's produce sample data for `tom` and `florent`](images/step-12-PRODUCE.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}'
+ kafka-console-producer --bootstrap-server localhost:6969 --producer.config teamA-sa.properties --topic customers-shredding
+ echo '{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}'
+ kafka-console-producer --bootstrap-server localhost:6969 --producer.config teamA-sa.properties --topic customers-shredding

```

</details>

## Let's consume the message, and confirm `tom` and `florent` are encrypted



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Let's consume the message, and confirm `tom` and `florent` are encrypted](images/step-13-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-console-consumer --bootstrap-server localhost:6969 --consumer.config teamA-sa.properties --topic customers-shredding --from-beginning --max-messages 2 --timeout-ms 5000
+ jq
Processed a total of 2 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "AAAABQAAAEl2YXVsdDp2MTpjdWV5WDVqc2RiWnlLWDE5VE1ZVE8vdnc2RUN2Tkx1RHpEOHkrci9WTWFrd3BNQ2huTU0wZ2hvU3V0NC8zQT09mgefc9TQhylzVxcsemgZRds83uO0f8ksqG0Xv4mU1JNU3i8fJtp9aU8zWRs=",
  "visa": "AAAABQAAAEl2YXVsdDp2MTo3bXdaaUliZ0ZxRyt1enUyRnJRb1FlbWJVNVFuYnhib3BxOFBFNTkyMEFBZlArZGFMRVJFTjdkbEFpV2tnQT09lUtyyTfZLT0y8NBTBTbGrbeJMYP2G9uPr1DJN78JkMJsdF/h7jD4N+wt",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "AAAABQAAAEl2YXVsdDp2MTpTTWlCZnhoWUJmcjkvU2ZJSW85VmJrbHFRaUcxc1lMekU2eHcrVlYxcldYR0pzWTNBeHFCbmpZZlRna2RzUT093iOt6cYzw2C4O0A6O6OcspU8CKU/aQ/AHQ+EcC+eKEJjR5ejuvysSOslyg==",
  "visa": "AAAABQAAAEl2YXVsdDp2MTpJWWJwZkF5bmk2UXFUa1YvcHJ0b2VFWHhyaHFwUFJBbzFOdFBmRForWG5vcTRYT1FDMTIvZFVTTmFTUWc1QT09EeE9mA/iH/NHddVlgXjj1JmLWg7WPmw+sV+LmfG6ocHbw8S3r5SB000AIDA=",
  "address": "Dubai, UAE"
}

```

</details>

## Let's add the decrypt interceptor to decipher messages




Creating the interceptor named `crypto-shredding-decrypt` of the plugin `io.conduktor.gateway.interceptor.DecryptPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.DecryptPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "customers-shredding",
    "kmsConfig" : {
      "vault" : {
        "uri" : "http://vault:8200",
        "token" : "vault-plaintext-root-token",
        "version" : 1
      }
    }
  }
}
```

Here's how to send it:

```sh
curl \
    --silent \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-decrypt" \
    --user 'admin:conduktor' \
    --header 'Content-Type: application/json' \
    --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.DecryptPlugin","priority":100,"config":{"topic":"customers-shredding","kmsConfig":{"vault":{"uri":"http://vault:8200","token":"vault-plaintext-root-token","version":1}}}}' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Let's add the decrypt interceptor to decipher messages](images/step-14-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ curl --silent --request POST http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-decrypt --user admin:conduktor --header 'Content-Type: application/json' --data-raw '{"pluginClass":"io.conduktor.gateway.interceptor.DecryptPlugin","priority":100,"config":{"topic":"customers-shredding","kmsConfig":{"vault":{"uri":"http://vault:8200","token":"vault-plaintext-root-token","version":1}}}}'
+ jq
{
  "message": "crypto-shredding-decrypt is created"
}

```

</details>

## List gateway interceptors



```sh
curl \
    -u "admin:conduktor" \
    --request GET "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptors" \
    --header 'Content-Type: application/json' | jq
```

<details>
  <summary>Realtime command output</summary>

  ![List gateway interceptors](images/step-15-LIST_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ curl -u admin:conduktor --request GET http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptors --header 'Content-Type: application/json'
+ jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0100   905  100   905    0     0  41000      0 --:--:-- --:--:-- --:--:-- 47631
{
  "interceptors": [
    {
      "name": "crypto-shredding-decrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": null,
      "config": {
        "topic": "customers-shredding",
        "kmsConfig": {
          "vault": {
            "uri": "http://vault:8200",
            "token": "vault-plaintext-root-token",
            "version": 1
          }
        }
      }
    },
    {
      "name": "crypto-shredding-encrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": null,
      "config": {
        "topic": "customers-shredding",
        "kmsConfig": {
          "vault": {
            "uri": "http://vault:8200",
            "token": "vault-plaintext-root-token",
            "version": 1
          }
        },
        "fields": [
          {
            "fieldName": "password",
            "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
            "algorithm": {
              "type": "AES_GCM",
              "kms": "VAULT"
            }
          },
          {
            "fieldName": "visa",
            "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
            "algorithm": {
              "type": "AES_GCM",
              "kms": "VAULT"
            }
          }
        ]
      }
    }
  ]
}

```

</details>

## Confirm message from `tom` and `florent` are encrypted



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Confirm message from `tom` and `florent` are encrypted](images/step-16-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-console-consumer --bootstrap-server localhost:6969 --consumer.config teamA-sa.properties --topic customers-shredding --from-beginning --max-messages 2 --timeout-ms 5000
+ jq
Processed a total of 2 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ",
  "address": "Dubai, UAE"
}

```

</details>

## Listing keys created in Vault



```sh
curl \
  --request GET 'http://localhost:8200/v1/transit/keys/?list=true' \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token" | jq -r ".data.keys"
```

<details>
  <summary>Realtime command output</summary>

  ![Listing keys created in Vault](images/step-17-SH.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ curl --request GET 'http://localhost:8200/v1/transit/keys/?list=true' --silent --header 'X-Vault-Token: vault-plaintext-root-token'
+ jq -r .data.keys
[
  "secret-for-florent",
  "secret-for-tom"
]

```

</details>

## Remove `florent` related keys



```sh
curl \
  --request POST 'http://localhost:8200/v1/transit/keys/secret-for-florent/config' \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token" \
  --header "content-type: application/json" \
  --data-raw '{"min_decryption_version":"1","min_encryption_version":1,"deletion_allowed":true,"auto_rotate_period":0}' > /dev/null

curl \
  --request DELETE http://localhost:8200/v1/transit/keys/secret-for-florent \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token"
```

<details>
  <summary>Realtime command output</summary>

  ![Remove `florent` related keys](images/step-18-SH.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ curl --request POST http://localhost:8200/v1/transit/keys/secret-for-florent/config --silent --header 'X-Vault-Token: vault-plaintext-root-token' --header 'content-type: application/json' --data-raw '{"min_decryption_version":"1","min_encryption_version":1,"deletion_allowed":true,"auto_rotate_period":0}'
+ curl --request DELETE http://localhost:8200/v1/transit/keys/secret-for-florent --silent --header 'X-Vault-Token: vault-plaintext-root-token'

```

</details>

## Let's make sure `florent` data are no more readable!



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 5000 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Let's make sure `florent` data are no more readable!](images/step-19-CONSUME.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ kafka-console-consumer --bootstrap-server localhost:6969 --consumer.config teamA-sa.properties --topic customers-shredding --from-beginning --max-messages 2 --timeout-ms 5000
+ jq
Processed a total of 2 messages
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "AAAABQAAAEl2YXVsdDp2MTpTTWlCZnhoWUJmcjkvU2ZJSW85VmJrbHFRaUcxc1lMekU2eHcrVlYxcldYR0pzWTNBeHFCbmpZZlRna2RzUT093iOt6cYzw2C4O0A6O6OcspU8CKU/aQ/AHQ+EcC+eKEJjR5ejuvysSOslyg==",
  "visa": "AAAABQAAAEl2YXVsdDp2MTpJWWJwZkF5bmk2UXFUa1YvcHJ0b2VFWHhyaHFwUFJBbzFOdFBmRForWG5vcTRYT1FDMTIvZFVTTmFTUWc1QT09EeE9mA/iH/NHddVlgXjj1JmLWg7WPmw+sV+LmfG6ocHbw8S3r5SB000AIDA=",
  "address": "Dubai, UAE"
}

```

</details>

## Cleanup the docker environment

Remove all components from docker

```sh
docker compose down -v
```

<details>
  <summary>Realtime command output</summary>

  ![Cleanup the docker environment](images/step-20-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
+ docker compose down -v
 Container cli-kcat  Stopping
 Container schema-registry  Stopping
 Container gateway2  Stopping
 Container vault  Stopping
 Container gateway1  Stopping
 Container vault  Stopped
 Container vault  Removing
 Container vault  Removed
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway1  Removed
 Container gateway2  Removed
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
 Container cli-kcat  Stopped
 Container cli-kcat  Removing
 Container cli-kcat  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network crypto-shredding-bouncy-castle_default  Removing
 Network crypto-shredding-bouncy-castle_default  Removed

```

</details>

# Conclusion

Crypto shredding help you protect your most precious information

