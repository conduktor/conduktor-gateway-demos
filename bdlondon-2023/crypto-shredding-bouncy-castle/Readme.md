# A full field level crypto shredding walkthrough



## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/VhUnK2RLMgUAthBvK1l4adTJh.svg)](https://asciinema.org/a/VhUnK2RLMgUAthBvK1l4adTJh)

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
      GATEWAY_SECURITY_PROVIDER: BOUNCY_CASTLE
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
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
    image: conduktor/conduktor-gateway:2.1.4
    hostname: gateway2
    container_name: gateway2
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
2023-09-20T11:01:02.649+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:213[m] - Enabling Bouncy Castle as Security Provider
2023-09-20T11:01:02.741+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider BCJSSE at position 0
2023-09-20T11:01:02.742+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SUN at position 1
2023-09-20T11:01:02.742+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunRsaSign at position 2
2023-09-20T11:01:02.742+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunEC at position 3
2023-09-20T11:01:02.742+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunJSSE at position 4
2023-09-20T11:01:02.743+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunJCE at position 5
2023-09-20T11:01:02.744+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunJGSS at position 6
2023-09-20T11:01:02.744+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunSASL at position 7
2023-09-20T11:01:02.745+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider XMLDSig at position 8
2023-09-20T11:01:02.746+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunPCSC at position 9
2023-09-20T11:01:02.747+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider JdkLDAP at position 10
2023-09-20T11:01:02.748+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider JdkSASL at position 11
2023-09-20T11:01:02.749+0000 [[31m      main[m] [[32mINFO [m] [[34mProxyConfiguration:229[m] - Security Provider SunPKCS11 at position 12
 

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
INFO: Found string security property [jdk.tls.disabledAlgorithms]: SSLv3, TLSv1, TLSv1.1, RC4, DES, MD5withRSA, DH keySize < 1024, EC keySize < 224, 3DES_EDE_CBC, anon, NULL
INFO: Found string security property [jdk.certpath.disabledAlgorithms]: MD2, MD5, SHA1 jdkCA step-06-SH-OUTPUT usage TLSServer, RSA keySize < 1024, DSA keySize < 1024, EC keySize < 224
WARNING: Ignoring unsupported entry in 'jdk.certpath.disabledAlgorithms': SHA1 jdkCA step-06-SH-OUTPUT usage TLSServer
 

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

  ![Creating virtual cluster `teamA`](images/step-07-CREATE_VIRTUAL_CLUSTERS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

## Creating topic `customers-shredding`

Creating topic `customers-shredding` on `teamA`
* topic `customers-shredding` with partitions:1 replication-factor:1

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

  ![Creating topic `customers-shredding`](images/step-08-CREATE_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
Created topic customers-shredding.
 

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

  ![Listing topics in `teamA`](images/step-09-LIST_TOPICS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
customers-shredding
 

```

</details>

## Adding interceptor `crypto-shredding-encrypt` in `gateway1`

Let's ask gateway to encrypt messages using vault and dynamic keys


Creating the interceptor named `crypto-shredding-encrypt` of the plugin ``io.conduktor.gateway.interceptor.EncryptPlugin using the following payload

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

  ![Adding interceptor `crypto-shredding-encrypt` in `gateway1`](images/step-10-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "crypto-shredding-encrypt is created"
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

  ![Listing interceptors for `teamA`](images/step-11-LIST_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
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

Producing 2 messages in `customers-shredding` in cluster `teamA`

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
 

```

</details>

## Let's consume the message, and confirm `tom` and `florent` are encrypted

Consuming from `customers-shredding` in cluster `teamA

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
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "AAAABQAAAEl2YXVsdDp2MTovYVV6aHcwR0RURkVMdDg4Z0E3WURXL01ZejB2YzMxY2ZzVCtkSUJSNVZQZERlSzZYUFJ5dHlXSXNGZzRMdz092N6vMEJV8KfUYtabSRZpV213pYeGc3r//lYGrROG9H5G6iXYXjZXe3bOPO4=",
  "visa": "AAAABQAAAEl2YXVsdDp2MTpDR1E2b0JZbE9xK1J1eG9URHBnWWwxcllPZFZJeDBrM3Q1Vk5BNHV0dHIxNGNHV2F3TG5kd01jS243VVRJUT09or9RnV5oSMGvQ3/XDrFq2cAc8hDqQMjkn0Cb+sBGlZR5NrbngwcmFtC+",
  "address": "Chancery lane, London"
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "AAAABQAAAEl2YXVsdDp2MTpvWEw1bkhGNytBVnV5LzVNUUZ1Tlgrd2JoeUtGeXZTU09UenhNT3E5SHVSWDZYRUZQa1pVYjZ2ODF0eHdXZz09XL9/lM3zyY3qXb/2t7mRvf8h5AvsXvDxfWyKwXKP297C82z37e2fCRDlFw==",
  "visa": "AAAABQAAAEl2YXVsdDp2MTplUjFRMUU2YTh2S1V0OWNtNFQ1L05nYVFXZUdMS1lsMHd4NWhZMU00cm5xeCtwVjNyNWtueWF3b0JOUEY2dz09tn2IJ8Vd54GKNDbiNL6axzv4zPbfzhIhuO2OPuRzQmlieD/22mD+VNQ7fUc=",
  "address": "Dubai, UAE"
}
 

```

</details>

## Adding interceptor `crypto-shredding-decrypt` in `gateway1`

Let's add the decrypt interceptor to decipher messages


Creating the interceptor named `crypto-shredding-decrypt` of the plugin ``io.conduktor.gateway.interceptor.DecryptPlugin using the following payload

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

  ![Adding interceptor `crypto-shredding-decrypt` in `gateway1`](images/step-14-ADD_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
{
  "message": "crypto-shredding-decrypt is created"
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

  ![Listing interceptors for `teamA`](images/step-15-LIST_INTERCEPTORS.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
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

Consuming from `customers-shredding` in cluster `teamA

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
 

```

</details>

## Let's make sure `florent` data are no more readable!

Consuming from `customers-shredding` in cluster `teamA

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
  "password": "AAAABQAAAEl2YXVsdDp2MTpvWEw1bkhGNytBVnV5LzVNUUZ1Tlgrd2JoeUtGeXZTU09UenhNT3E5SHVSWDZYRUZQa1pVYjZ2ODF0eHdXZz09XL9/lM3zyY3qXb/2t7mRvf8h5AvsXvDxfWyKwXKP297C82z37e2fCRDlFw==",
  "visa": "AAAABQAAAEl2YXVsdDp2MTplUjFRMUU2YTh2S1V0OWNtNFQ1L05nYVFXZUdMS1lsMHd4NWhZMU00cm5xeCtwVjNyNWtueWF3b0JOUEY2dz09tn2IJ8Vd54GKNDbiNL6axzv4zPbfzhIhuO2OPuRzQmlieD/22mD+VNQ7fUc=",
  "address": "Dubai, UAE"
}
 

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

  ![Cleanup the docker environment](images/step-20-DOCKER.gif)

</details>

<details>
  <summary>Command output</summary>

```sh
 

```

</details>

# Conclusion

Crypto shredding help you protect your most precious information

