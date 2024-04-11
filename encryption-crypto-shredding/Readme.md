# A full field level crypto shredding walkthrough



## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/UowAgTw44xlwWvdYo7FPiWk7K.svg)](https://asciinema.org/a/UowAgTw44xlwWvdYo7FPiWk7K)

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
 Network encryption-crypto-shredding_default  Creating
 Network encryption-crypto-shredding_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container vault  Creating
 Container kafka-client  Created
 Container vault  Created
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka2  Created
 Container kafka3  Created
 Container kafka1  Created
 Container gateway2  Creating
 Container gateway1  Creating
 Container schema-registry  Creating
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container kafka-client  Starting
 Container zookeeper  Starting
 Container vault  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container vault  Started
 Container kafka-client  Started
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container kafka1  Started
 Container kafka3  Started
 Container kafka2  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container gateway1  Starting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway2  Starting
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container schema-registry  Starting
 Container gateway2  Started
 Container schema-registry  Started
 Container gateway1  Started
 Container zookeeper  Waiting
 Container kafka3  Waiting
 Container vault  Waiting
 Container kafka-client  Waiting
 Container gateway2  Waiting
 Container kafka1  Waiting
 Container gateway1  Waiting
 Container schema-registry  Waiting
 Container kafka2  Waiting
 Container kafka2  Healthy
 Container kafka-client  Healthy
 Container zookeeper  Healthy
 Container kafka3  Healthy
 Container vault  Healthy
 Container kafka1  Healthy
 Container gateway1  Healthy
 Container schema-registry  Healthy
 Container gateway2  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/J7gGmD1IyvujytoBIFOtw5BK3.svg)](https://asciinema.org/a/J7gGmD1IyvujytoBIFOtw5BK3)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ3MTk4OH0.bYzPnp3oq-55HGCu5HCfvJhewZNH4XTINKSBvax5u_4';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/YjJDHeVrwsogaVPQIl6adej3T.svg)](https://asciinema.org/a/YjJDHeVrwsogaVPQIl6adej3T)

</details>

## Creating topic customers-shredding on teamA

Creating on `teamA`:

* Topic `customers-shredding` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic customers-shredding
```



</details>
<details>
<summary>Output</summary>

```
Created topic customers-shredding.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/eAqd6tq56OUIdWUhPDXMgjK4y.svg)](https://asciinema.org/a/eAqd6tq56OUIdWUhPDXMgjK4y)

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
customers-shredding

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/zoYB28VvZg0FgdaG6WenpM6zN.svg)](https://asciinema.org/a/zoYB28VvZg0FgdaG6WenpM6zN)

</details>

## Adding interceptor crypto-shredding-encrypt

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

[![asciicast](https://asciinema.org/a/aVCerK4oBUd3EyX4mDXkU6Oom.svg)](https://asciinema.org/a/aVCerK4oBUd3EyX4mDXkU6Oom)

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

[![asciicast](https://asciinema.org/a/7oMgx8A9a5ovbXKIsHeI4BQFG.svg)](https://asciinema.org/a/7oMgx8A9a5ovbXKIsHeI4BQFG)

</details>

## Let's produce sample data for tom and laura

Producing 2 messages in `customers-shredding` in cluster `teamA`

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
        --topic customers-shredding

echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers-shredding
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/cVcPqOLNISXolxoyZgDyj7kRt.svg)](https://asciinema.org/a/cVcPqOLNISXolxoyZgDyj7kRt)

</details>

## Let's consume the message, and confirm tom and laura are encrypted

Let's consume the message, and confirm tom and laura are encrypted in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 2 events
```json
{
  "name" : "laura",
  "username" : "laura@conduktor.io",
  "password" : "AAAABQAAAAEAAABJdmF1bHQ6djE6WXVmMUp5cTM2cUtFUUNDaVpQQ09vT1ZTZWhSTUxsZ1Rvd051WEpiK3lIOXMxT3RBcGU0Y0xPSHVNMzJZQ3c9PUW1O9hJBFOdHDjV6Z10leHvd2E22QitKoM02D+SgjeLXlC1Y+VBnHlIIkY=",
  "visa" : "AAAABQAAAAEAAABJdmF1bHQ6djE6WXVmMUp5cTM2cUtFUUNDaVpQQ09vT1ZTZWhSTUxsZ1Rvd051WEpiK3lIOXMxT3RBcGU0Y0xPSHVNMzJZQ3c9PQU3oYki9GuW9j3Vq7+Lj1fVfnKJrtZKNpVzE5YzIuEhq0vY3wT41xl2L0pS",
  "address" : "Dubai, UAE"
}
{
  "name" : "tom",
  "username" : "tom@conduktor.io",
  "password" : "AAAABQAAAAEAAABJdmF1bHQ6djE6VGNtdGcwdEU4bkNucU9kV0xGQWRjQXZzVXJ3bUxSOXNMVm51TCtjTGpkSSt0NXJOaTFQYzhKZU9veU9CS3c9PXK5SEikrCnhMUTImgVWa8OisKzZIHjw2cRqUJrcE0WXRc2/+ny+UQYOB1Cd",
  "visa" : "AAAABQAAAAEAAABJdmF1bHQ6djE6VGNtdGcwdEU4bkNucU9kV0xGQWRjQXZzVXJ3bUxSOXNMVm51TCtjTGpkSSt0NXJOaTFQYzhKZU9veU9CS3c9PT5PT6k9G2kkJB05CLSqPb5FjSJtecYf5DcVEPpIEhKnkc7acF9cz5/7vQ==",
  "address" : "Chancery lane, London"
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 00:53:27,265] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "laura",
  "username": "laura@conduktor.io",
  "password": "AAAABQAAAAEAAABJdmF1bHQ6djE6ajA0MXFyK09hcEswcUE1MzlrOVB3bHcwSXNtbUdYV3k2emtJbE9rZ00wUFBlQ254SWhBbEViSmdzd2ljMEE9PTX4VrzUrdThwR6dFioySSveL0T0QEi+NxIzaz4RQQ+1coEL0FSDE6i4akE=",
  "visa": "AAAABQAAAAEAAABJdmF1bHQ6djE6ajA0MXFyK09hcEswcUE1MzlrOVB3bHcwSXNtbUdYV3k2emtJbE9rZ00wUFBlQ254SWhBbEViSmdzd2ljMEE9Pe7mWHAVHw2H5tS1uxrjVn2PVb8NU6VqdKhQNqIqdXtr73Cd3M5NyATylO5l",
  "address": "Dubai, UAE"
}
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "AAAABQAAAAEAAABJdmF1bHQ6djE6SEN3bG5lYlhkR3piZURsZ3k2OHZQa1lTR2RSTm51TXZMQTk2SkJpNDdSNC96cmRyRFNCWDlBbkN1bGQ1Mmc9PTwFrptKoMRbsEGVroZrNo5N3MGLtzUAVyUIaAhcj5C55cfUc7tMW7Ux8eYK",
  "visa": "AAAABQAAAAEAAABJdmF1bHQ6djE6SEN3bG5lYlhkR3piZURsZ3k2OHZQa1lTR2RSTm51TXZMQTk2SkJpNDdSNC96cmRyRFNCWDlBbkN1bGQ1Mmc9PZn6ks7Upp48eJnCo1aAKmFFlgaPQ0j4hi9xixmdThO3pfBq1mBsKVLYNA==",
  "address": "Chancery lane, London"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/piud6JKve7pq1tqmCBZ421Jl7.svg)](https://asciinema.org/a/piud6JKve7pq1tqmCBZ421Jl7)

</details>

## Adding interceptor crypto-shredding-decrypt

Let's add the decrypt interceptor to decipher messages

Creating the interceptor named `crypto-shredding-decrypt` of the plugin `io.conduktor.gateway.interceptor.DecryptPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.DecryptPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "customers-shredding",
    "kmsConfig" : {
      "keyTtlMs" : 200,
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
    "topic": "customers-shredding",
    "kmsConfig": {
      "keyTtlMs": 200,
      "vault": {
        "uri": "http://vault:8200",
        "token": "vault-plaintext-root-token",
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

[![asciicast](https://asciinema.org/a/QcdbpYQ8Kx8z18GCjuCGkzaab.svg)](https://asciinema.org/a/QcdbpYQ8Kx8z18GCjuCGkzaab)

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
        "topic": "customers-shredding",
        "kmsConfig": {
          "keyTtlMs": 200,
          "vault": {
            "uri": "http://vault:8200",
            "token": "vault-plaintext-root-token",
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

[![asciicast](https://asciinema.org/a/pU0S9EOAbNn70IldzDFxv14kX.svg)](https://asciinema.org/a/pU0S9EOAbNn70IldzDFxv14kX)

</details>

## Confirm message from tom and laura are encrypted

Confirm message from tom and laura are encrypted in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
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
[2024-04-10 00:53:39,587] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
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

[![asciicast](https://asciinema.org/a/QnCZbkg4MjsiGjimHaSBYse2E.svg)](https://asciinema.org/a/QnCZbkg4MjsiGjimHaSBYse2E)

</details>

## Listing keys created in Vault



<details open>
<summary>Command</summary>



```sh
curl \
  --request GET 'http://localhost:8200/v1/transit/keys/?list=true' \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token" | jq -r ".data.keys"
```



</details>
<details>
<summary>Output</summary>

```
[
  "secret-for-laura",
  "secret-for-tom"
]

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/K28vaFw8rdAm5E3Qn9IJrBQse.svg)](https://asciinema.org/a/K28vaFw8rdAm5E3Qn9IJrBQse)

</details>

## Remove laura related keys



<details>
<summary>Command</summary>



```sh
curl \
  --request POST 'http://localhost:8200/v1/transit/keys/secret-for-laura/config' \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token" \
  --header "content-type: application/json" \
  --data-raw '{"min_decryption_version":"1","min_encryption_version":1,"deletion_allowed":true,"auto_rotate_period":0}' > /dev/null

curl \
  --request DELETE http://localhost:8200/v1/transit/keys/secret-for-laura \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token"
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Uz7z1337ZqtcFUlwJ6OD97V8P.svg)](https://asciinema.org/a/Uz7z1337ZqtcFUlwJ6OD97V8P)

</details>

## Let's make sure laura data are no more readable!

Let's make sure laura data are no more readable! in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-shredding \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 2 events
```json
{
  "name" : "laura",
  "username" : "laura@conduktor.io",
  "password" : "AAAABQAAAAEAAABJdmF1bHQ6djE6WXVmMUp5cTM2cUtFUUNDaVpQQ09vT1ZTZWhSTUxsZ1Rvd051WEpiK3lIOXMxT3RBcGU0Y0xPSHVNMzJZQ3c9PUW1O9hJBFOdHDjV6Z10leHvd2E22QitKoM02D+SgjeLXlC1Y+VBnHlIIkY=",
  "visa" : "AAAABQAAAAEAAABJdmF1bHQ6djE6WXVmMUp5cTM2cUtFUUNDaVpQQ09vT1ZTZWhSTUxsZ1Rvd051WEpiK3lIOXMxT3RBcGU0Y0xPSHVNMzJZQ3c9PQU3oYki9GuW9j3Vq7+Lj1fVfnKJrtZKNpVzE5YzIuEhq0vY3wT41xl2L0pS",
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
[2024-04-10 00:53:51,974] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages
{
  "name": "laura",
  "username": "laura@conduktor.io",
  "password": "AAAABQAAAAEAAABJdmF1bHQ6djE6ajA0MXFyK09hcEswcUE1MzlrOVB3bHcwSXNtbUdYV3k2emtJbE9rZ00wUFBlQ254SWhBbEViSmdzd2ljMEE9PTX4VrzUrdThwR6dFioySSveL0T0QEi+NxIzaz4RQQ+1coEL0FSDE6i4akE=",
  "visa": "AAAABQAAAAEAAABJdmF1bHQ6djE6ajA0MXFyK09hcEswcUE1MzlrOVB3bHcwSXNtbUdYV3k2emtJbE9rZ00wUFBlQ254SWhBbEViSmdzd2ljMEE9Pe7mWHAVHw2H5tS1uxrjVn2PVb8NU6VqdKhQNqIqdXtr73Cd3M5NyATylO5l",
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

[![asciicast](https://asciinema.org/a/IkynW9Y864OC10CbBhbOe280r.svg)](https://asciinema.org/a/IkynW9Y864OC10CbBhbOe280r)

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
 Container vault  Stopping
 Container kafka-client  Stopping
 Container schema-registry  Stopping
 Container gateway2  Stopping
 Container gateway1  Stopping
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
 Container kafka1  Stopping
 Container kafka3  Stopping
 Container kafka2  Stopping
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
 Network encryption-crypto-shredding_default  Removing
 Network encryption-crypto-shredding_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/CRnX2FK21Y0JcZJNmee365qZ8.svg)](https://asciinema.org/a/CRnX2FK21Y0JcZJNmee365qZ8)

</details>

# Conclusion

Crypto shredding help you protect your most precious information

