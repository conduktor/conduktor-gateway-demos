# A full field level crypto shredding walkthrough



## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/2uTAAN2phRpIE9YmSJD4ewgJu.svg)](https://asciinema.org/a/2uTAAN2phRpIE9YmSJD4ewgJu)

### Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
* kafka1
* kafka2
* kafka3
* schema-registry
* vault
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

 <details>
  <summary>docker compose ps</summary>

```
NAME              IMAGE                                    COMMAND                  SERVICE           CREATED          STATUS                    PORTS
gateway1          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway1          27 seconds ago   Up 15 seconds (healthy)   0.0.0.0:6969-6971->6969-6971/tcp, 0.0.0.0:8888->8888/tcp
gateway2          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway2          27 seconds ago   Up 15 seconds (healthy)   0.0.0.0:7969-7971->7969-7971/tcp, 0.0.0.0:8889->8888/tcp
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            27 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            27 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
kafka3            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka3            27 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19094->19094/tcp
schema-registry   confluentinc/cp-schema-registry:latest   "/etc/confluent/dock…"   schema-registry   27 seconds ago   Up 15 seconds (healthy)   0.0.0.0:8081->8081/tcp
vault             hashicorp/vault                          "docker-entrypoint.s…"   vault             27 seconds ago   Up 27 seconds (healthy)   0.0.0.0:8200->8200/tcp
zookeeper         confluentinc/cp-zookeeper:latest         "/etc/confluent/dock…"   zookeeper         27 seconds ago   Up 27 seconds (healthy)   2181/tcp, 2888/tcp, 3888/tcp

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
 Network encryption-crypto-shredding_default  Creating
 Network encryption-crypto-shredding_default  Created
 Container zookeeper  Creating
 Container vault  Creating
 Container vault  Created
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka2  Created
 Container kafka1  Created
 Container kafka3  Created
 Container gateway2  Creating
 Container gateway1  Creating
 Container schema-registry  Creating
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway1  Created
 Container gateway2  Created
 Container schema-registry  Created
 Container zookeeper  Starting
 Container vault  Starting
 Container vault  Started
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
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
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container gateway1  Starting
 Container kafka3  Healthy
 Container gateway2  Starting
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container gateway2  Started
 Container gateway1  Started
 Container schema-registry  Started
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container vault  Waiting
 Container zookeeper  Waiting
 Container vault  Healthy
 Container kafka1  Healthy
 Container zookeeper  Healthy
 Container kafka2  Healthy
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
      


## Creating topic `customers-shredding` on `teamA`

Creating topic `customers-shredding` on `teamA`
* Topic `customers-shredding` with partitions:1 and replication-factor:1

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

  ![Creating topic `customers-shredding` on `teamA`](images/step-06-CREATE_TOPICS.gif)

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
    --topic customers-shredding
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

  ![Listing topics in `teamA`](images/step-07-LIST_TOPICS.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
customers-shredding

```

</details>
      


## Adding interceptor `crypto-shredding-encrypt`

Let's ask gateway to encrypt messages using vault and dynamic keys


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
cat step-08-crypto-shredding-encrypt.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-encrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-crypto-shredding-encrypt.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `crypto-shredding-encrypt`](images/step-08-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-08-crypto-shredding-encrypt.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
  "priority": 100,
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

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-encrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-crypto-shredding-encrypt.json | jq
{
  "message": "crypto-shredding-encrypt is created"
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

  ![Listing interceptors for `teamA`](images/step-09-LIST_INTERCEPTORS.gif)

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
      "name": "crypto-shredding-encrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
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
echo '{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers-shredding

echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers-shredding
```

<details>
  <summary>Realtime command output</summary>

  ![Let's produce sample data for `tom` and `florent`](images/step-10-PRODUCE.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers-shredding

echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers-shredding

```

</details>
      


## Let's consume the message, and confirm `tom` and `florent` are encrypted

Let's consume the message, and confirm `tom` and `florent` are encrypted in cluster `teamA`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Let's consume the message, and confirm `tom` and `florent` are encrypted](images/step-11-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 18:44:29,467] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "AAAABQAAAEl2YXVsdDp2MTo3WlBwbkNvbDV6MldBVU5OOWFCb3hNUEwzdGloaHFvUlZQWEp5QXJLWk45ZEdXRThCcXZZQTlTdk5KL3RlZz09AbeObkx5xHvroJXGN4kDUkOoR2txR+18qvrdx3a05CRLOq0K36nDVMk2YQ==",
  "visa": "AAAABQAAAEl2YXVsdDp2MTo5QUd4aG40cDdlamJ3ZWNicHJwekRGNWR3K1hGNGZYL2ZoY09rQkJLZGp0NVF2WHpsTW1ubzd5aDVTZXpYQT09YQTd/OqhYTbNXyp0FuQu2uVcaBA/ay4d8N6tyfO3ieSKRxrGF+yh40jdGFc=",
  "address": "Dubai, UAE"
}
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "AAAABQAAAEl2YXVsdDp2MTo3S2F3cHFyTEhRZ3hkd2ZiMnpPOWFnUEJNU09nN2V6OElJUkZaTlJ0ZHVFSFM5cUtyV0R2cW9TNkxoYkRFdz09xpFbv+O0Utw54N+5ToRvqirQhy8MdSqFVPMODF50FC1HG0W4Ucdib6HxvlI=",
  "visa": "AAAABQAAAEl2YXVsdDp2MTpkSlE0eHlGNFo0d3hIV2VPamUzdGdaWU43YWVwRnFjRSsxcnArUDFpNVBUcDROVWxuSS9EYXQ4aVVFa25EZz094Z6Fc/w9YV0joAS4vImBt4hhTNU5gm9iCsUy5yMXMQ2rP/Jwz/69+9yD",
  "address": "Chancery lane, London"
}

```

</details>
      


## Adding interceptor `crypto-shredding-decrypt`

Let's add the decrypt interceptor to decipher messages


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
cat step-12-crypto-shredding-decrypt.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-decrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-12-crypto-shredding-decrypt.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `crypto-shredding-decrypt`](images/step-12-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-12-crypto-shredding-decrypt.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
  "priority": 100,
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
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-decrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-12-crypto-shredding-decrypt.json | jq
{
  "message": "crypto-shredding-decrypt is created"
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

  ![Listing interceptors for `teamA`](images/step-13-LIST_INTERCEPTORS.gif)

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
      "name": "crypto-shredding-decrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
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
      "timeoutMs": 9223372036854775807,
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

Confirm message from `tom` and `florent` are encrypted in cluster `teamA`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Confirm message from `tom` and `florent` are encrypted](images/step-14-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 18:44:41,532] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ",
  "address": "Dubai, UAE"
}
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
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

  ![Listing keys created in Vault](images/step-15-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

curl \
  --request GET 'http://localhost:8200/v1/transit/keys/?list=true' \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token" | jq -r ".data.keys"
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

  ![Remove `florent` related keys](images/step-16-SH.gif)

</details>


<details>
<summary>Command output</summary>

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

</details>
      


## Let's make sure `florent` data are no more readable!

Let's make sure `florent` data are no more readable! in cluster `teamA`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Let's make sure `florent` data are no more readable!](images/step-17-CONSUME.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --timeout-ms 10000 \
 | jq
[2024-01-22 18:44:53,430] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "AAAABQAAAEl2YXVsdDp2MTo3WlBwbkNvbDV6MldBVU5OOWFCb3hNUEwzdGloaHFvUlZQWEp5QXJLWk45ZEdXRThCcXZZQTlTdk5KL3RlZz09AbeObkx5xHvroJXGN4kDUkOoR2txR+18qvrdx3a05CRLOq0K36nDVMk2YQ==",
  "visa": "AAAABQAAAEl2YXVsdDp2MTo5QUd4aG40cDdlamJ3ZWNicHJwekRGNWR3K1hGNGZYL2ZoY09rQkJLZGp0NVF2WHpsTW1ubzd5aDVTZXpYQT09YQTd/OqhYTbNXyp0FuQu2uVcaBA/ay4d8N6tyfO3ieSKRxrGF+yh40jdGFc=",
  "address": "Dubai, UAE"
}
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": "Chancery lane, London"
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
 Container vault  Stopping
 Container gateway1  Stopping
 Container schema-registry  Stopping
 Container gateway2  Stopping
 Container vault  Stopped
 Container vault  Removing
 Container vault  Removed
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
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network encryption-crypto-shredding_default  Removing
 Network encryption-crypto-shredding_default  Removed

```

</details>
      


# Conclusion

Crypto shredding help you protect your most precious information

