# A full field level with Vault and secret management



## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/FbsCtrpkMJATRa5dflEaIONTJ.svg)](https://asciinema.org/a/FbsCtrpkMJATRa5dflEaIONTJ)

## Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
* kafka-client
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
    image: conduktor/conduktor-gateway:3.0.0
    hostname: gateway1
    container_name: gateway1
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_MODE: VCLUSTER
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      VAULT_TOKEN: vault-plaintext-root-token
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
      GATEWAY_MODE: VCLUSTER
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_START_PORT: 7969
      VAULT_TOKEN: vault-plaintext-root-token
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
 Network encryption-vault-with-secret-management_default  Creating
 Network encryption-vault-with-secret-management_default  Created
 Container kafka-client  Creating
 Container zookeeper  Creating
 Container vault  Creating
 Container kafka-client  Created
 Container vault  Created
 Container zookeeper  Created
 Container kafka1  Creating
 Container kafka2  Creating
 Container kafka3  Creating
 Container kafka2  Created
 Container kafka3  Created
 Container kafka1  Created
 Container gateway1  Creating
 Container schema-registry  Creating
 Container gateway2  Creating
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container zookeeper  Starting
 Container kafka-client  Starting
 Container vault  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container vault  Started
 Container kafka-client  Started
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container kafka1  Started
 Container kafka3  Started
 Container kafka2  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container schema-registry  Starting
 Container kafka3  Healthy
 Container gateway1  Starting
 Container kafka2  Healthy
 Container gateway2  Starting
 Container schema-registry  Started
 Container gateway2  Started
 Container gateway1  Started
 Container kafka3  Waiting
 Container gateway2  Waiting
 Container vault  Waiting
 Container gateway1  Waiting
 Container schema-registry  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container zookeeper  Waiting
 Container kafka-client  Waiting
 Container vault  Healthy
 Container kafka-client  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container zookeeper  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/zfao7LJOqjL9pGIj5ClcjqsoK.svg)](https://asciinema.org/a/zfao7LJOqjL9pGIj5ClcjqsoK)

</details>

## Creating virtual cluster teamA

Creating virtual cluster `teamA` on gateway `gateway1` and reviewing the configuration file to access it

<details>
<summary>Command</summary>



```sh
# Generate virtual cluster teamA with service account sa
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

# Create access file
echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > teamA-sa.properties

# Review file
cat teamA-sa.properties
```



</details>
<details>
<summary>Output</summary>

```

bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ3NjEwMX0.0KXNru_-jobj-zkWIBGATrSyzqIvH3rqhKghcXtx8bQ';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Cpfdv2DRVAFMphYW1vibywx1d.svg)](https://asciinema.org/a/Cpfdv2DRVAFMphYW1vibywx1d)

</details>

## Creating topic customers on teamA

Creating on `teamA`:

* Topic `customers` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic customers
```



</details>
<details>
<summary>Output</summary>

```
Created topic customers.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/bY8YtKqOcKN0l8yqXgrOX0EP3.svg)](https://asciinema.org/a/bY8YtKqOcKN0l8yqXgrOX0EP3)

</details>

## Listing topics in teamA



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
```



</details>
<details>
<summary>Output</summary>

```
customers

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/lpSINWubhon9oyqpa5Ed9tGpP.svg)](https://asciinema.org/a/lpSINWubhon9oyqpa5Ed9tGpP)

</details>

## Adding interceptor crypto-shredding-encrypt

Let's ask gateway to encrypt messages using vault and secret management.
The vault token is retrieved from your env variable `${VAULT_TOKEN}`.

Creating the interceptor named `crypto-shredding-encrypt` of the plugin `io.conduktor.gateway.interceptor.EncryptPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.EncryptPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "customers",
    "kmsConfig" : {
      "vault" : {
        "uri" : "http://vault:8200",
        "token" : "${VAULT_TOKEN}",
        "version" : 1
      }
    },
    "fields" : [ {
      "fieldName" : "password",
      "keySecretId" : "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
      "algorithm" : "AES_GCM"
    }, {
      "fieldName" : "visa",
      "keySecretId" : "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
      "algorithm" : "AES_GCM"
    } ]
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-08-crypto-shredding-encrypt.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-encrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-crypto-shredding-encrypt.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
  "priority": 100,
  "config": {
    "topic": "customers",
    "kmsConfig": {
      "vault": {
        "uri": "http://vault:8200",
        "token": "${VAULT_TOKEN}",
        "version": 1
      }
    },
    "fields": [
      {
        "fieldName": "password",
        "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
        "algorithm": "AES_GCM"
      },
      {
        "fieldName": "visa",
        "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
        "algorithm": "AES_GCM"
      }
    ]
  }
}
{
  "message": "crypto-shredding-encrypt is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/ExGordjORzZKUTke8Vsw0B2IC.svg)](https://asciinema.org/a/ExGordjORzZKUTke8Vsw0B2IC)

</details>

## Listing interceptors for teamA

Listing interceptors on `gateway1` for virtual cluster `teamA`

<details open>
<summary>Command</summary>



```sh
curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/teamA' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "interceptors": [
    {
      "name": "crypto-shredding-encrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "topic": "customers",
        "kmsConfig": {
          "vault": {
            "uri": "http://vault:8200",
            "token": "${VAULT_TOKEN}",
            "version": 1
          }
        },
        "fields": [
          {
            "fieldName": "password",
            "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
            "algorithm": "AES_GCM"
          },
          {
            "fieldName": "visa",
            "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
            "algorithm": "AES_GCM"
          }
        ]
      }
    }
  ]
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/BdbHOBRvcQZUR86GoZZ4Dld31.svg)](https://asciinema.org/a/BdbHOBRvcQZUR86GoZZ4Dld31)

</details>

## Let's produce sample data for tom and laura

Producing 2 messages in `customers` in cluster `teamA`

<details>
<summary>Command</summary>



Sending 2 events
```json
{
  "name" : "laura",
  "username" : "laura@conduktor.io",
  "password" : "kitesurf",
  "visa" : "#888999XZ",
  "address" : "Dubai, UAE"
}
{
  "name" : "tom",
  "username" : "tom@conduktor.io",
  "password" : "motorhead",
  "visa" : "#abc123",
  "address" : "Chancery lane, London"
}
```
with


```sh
echo '{"name":"laura","username":"laura@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers

echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/xQ11DJLhTsLleJOLxR0xcL1Mf.svg)](https://asciinema.org/a/xQ11DJLhTsLleJOLxR0xcL1Mf)

</details>

## Let's consume the message, and confirm tom and laura are encrypted

Let's consume the message, and confirm tom and laura are encrypted in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 2 events
```json
{
  "name" : "laura",
  "username" : "laura@conduktor.io",
  "password" : "AAAABQAAAAEAAABJdmF1bHQ6djE6LzN5WTVNVzJZdDVEMkNIZ2JNRjA4akRXL0wwS2VVL2JXZGV6Ryt5UkFyR3FCWFB0bXNqZVV1b0ZUbUxjRGc9PZ6QsOyTVE0JFze6hCkZN6/ZvnNn+vjMEtxlDcSB2LouMiYlbpF/hk38EPw=",
  "visa" : "AAAABQAAAAEAAABJdmF1bHQ6djE6LzN5WTVNVzJZdDVEMkNIZ2JNRjA4akRXL0wwS2VVL2JXZGV6Ryt5UkFyR3FCWFB0bXNqZVV1b0ZUbUxjRGc9PfwlVRpVwL6k9MEyHSG6WJXSSSve2ubnINjYQFM52HXR10AFL+k8IuBuQ2CR",
  "address" : "Dubai, UAE"
}
{
  "name" : "tom",
  "username" : "tom@conduktor.io",
  "password" : "AAAABQAAAAEAAABJdmF1bHQ6djE6MEpTMEJEV2sybUN1OWg5cDgzNElkeVVBZVVFV0NDTXZlNlI0WFA1TUk2Q1VyakNiYkp3a1haeld3bml2dFE9PU/0AZYmzS0Mg4MDuCv9zrBOHXjHqv/buw7ifBs1+hXe2sfKokQOeaEsJmrH",
  "visa" : "AAAABQAAAAEAAABJdmF1bHQ6djE6MEpTMEJEV2sybUN1OWg5cDgzNElkeVVBZVVFV0NDTXZlNlI0WFA1TUk2Q1VyakNiYkp3a1haeld3bml2dFE9Pc5xlMwSiszb2SujkrWVCPemgoqlDTL/qnFx1IdDz20Xlb9UdZgrfoAdtg==",
  "address" : "Chancery lane, London"
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 02:01:59,514] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "laura",
  "username": "laura@conduktor.io",
  "password": "AAAABQAAAAEAAABJdmF1bHQ6djE6bzdFdmVxSEEvVVBPSHdjSi93WkZ0NUFMMmRORC9aMEhpc1dncmtabkZwVGlsUGl2ekFJTGYyNGpwN2JrU2c9PS3I5hL2w7YKmTgTBvfRFrg7puvYvXz4bspWKwmpD3ZdadzVI5p9EX9vzUw=",
  "visa": "AAAABQAAAAEAAABJdmF1bHQ6djE6bzdFdmVxSEEvVVBPSHdjSi93WkZ0NUFMMmRORC9aMEhpc1dncmtabkZwVGlsUGl2ekFJTGYyNGpwN2JrU2c9PUl3AIAtkm7IC09QX/SFMlvVYUnQFxIkULguQpH4HaWiXeXaJpDEy3QYShXp",
  "address": "Dubai, UAE"
}
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "AAAABQAAAAEAAABJdmF1bHQ6djE6UGN2ZWdYSEY0OXdOck1ZWGZwRmtDZUxaYzYwMDlyUlVQSENHSmJlTHJWOGRwamVEL2ZRTkdUQVpLNnk2MWc9PfJ/X2/EtJ0QpAcyJjeZJq4UWEwNtAOsmRBMICAZ7Co6cqnR8BMZsbNGMtSm",
  "visa": "AAAABQAAAAEAAABJdmF1bHQ6djE6UGN2ZWdYSEY0OXdOck1ZWGZwRmtDZUxaYzYwMDlyUlVQSENHSmJlTHJWOGRwamVEL2ZRTkdUQVpLNnk2MWc9PYxnBe+5gmjwiO23f8fLmiUGtW395i7IDhLHBz/Jy+FSOs8Id7TquxcZog==",
  "address": "Chancery lane, London"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/F5o1sSNXBYaihyNjujjGfgTeE.svg)](https://asciinema.org/a/F5o1sSNXBYaihyNjujjGfgTeE)

</details>

## Adding interceptor crypto-shredding-decrypt

Let's add the decrypt interceptor to decipher messages.
The vault token is retrieved from your env variable `${VAULT_TOKEN}`.

Creating the interceptor named `crypto-shredding-decrypt` of the plugin `io.conduktor.gateway.interceptor.DecryptPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.DecryptPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "customers",
    "kmsConfig" : {
      "vault" : {
        "uri" : "http://vault:8200",
        "token" : "${VAULT_TOKEN}",
        "version" : 1
      }
    }
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-12-crypto-shredding-decrypt.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/crypto-shredding-decrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-12-crypto-shredding-decrypt.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
  "priority": 100,
  "config": {
    "topic": "customers",
    "kmsConfig": {
      "vault": {
        "uri": "http://vault:8200",
        "token": "${VAULT_TOKEN}",
        "version": 1
      }
    }
  }
}
{
  "message": "crypto-shredding-decrypt is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/hVktcWzHHKSHRWDjUmzSa4MP5.svg)](https://asciinema.org/a/hVktcWzHHKSHRWDjUmzSa4MP5)

</details>

## Listing interceptors for teamA

Listing interceptors on `gateway1` for virtual cluster `teamA`

<details open>
<summary>Command</summary>



```sh
curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/teamA' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "interceptors": [
    {
      "name": "crypto-shredding-encrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "topic": "customers",
        "kmsConfig": {
          "vault": {
            "uri": "http://vault:8200",
            "token": "${VAULT_TOKEN}",
            "version": 1
          }
        },
        "fields": [
          {
            "fieldName": "password",
            "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
            "algorithm": "AES_GCM"
          },
          {
            "fieldName": "visa",
            "keySecretId": "vault-kms://vault:8200/transit/keys/secret-for-{{record.value.name}}",
            "algorithm": "AES_GCM"
          }
        ]
      }
    },
    {
      "name": "crypto-shredding-decrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "topic": "customers",
        "kmsConfig": {
          "vault": {
            "uri": "http://vault:8200",
            "token": "${VAULT_TOKEN}",
            "version": 1
          }
        }
      }
    }
  ]
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/E6jnnbt6jbAANx489y0XfBjNi.svg)](https://asciinema.org/a/E6jnnbt6jbAANx489y0XfBjNi)

</details>

## Confirm message from tom and laura are encrypted

Confirm message from tom and laura are encrypted in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 2 events
```json
{
  "name" : "laura",
  "username" : "laura@conduktor.io",
  "password" : "kitesurf",
  "visa" : "#888999XZ",
  "address" : "Dubai, UAE"
}
{
  "name" : "tom",
  "username" : "tom@conduktor.io",
  "password" : "motorhead",
  "visa" : "#abc123",
  "address" : "Chancery lane, London"
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 02:02:11,671] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "laura",
  "username": "laura@conduktor.io",
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
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/aUqp2uunoY3be3XombFE2Gfk8.svg)](https://asciinema.org/a/aUqp2uunoY3be3XombFE2Gfk8)

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
 Container vault  Stopping
 Container schema-registry  Stopping
 Container gateway2  Stopping
 Container vault  Stopped
 Container vault  Removing
 Container vault  Removed
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
 Network encryption-vault-with-secret-management_default  Removing
 Network encryption-vault-with-secret-management_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/pfERWy32aqHvCsCOftxY7LDrk.svg)](https://asciinema.org/a/pfERWy32aqHvCsCOftxY7LDrk)

</details>

# Conclusion

Crypto shredding help you protect your most precious information

