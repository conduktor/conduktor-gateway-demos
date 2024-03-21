# Encryption key

Let's demonstrate encryption for key

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

![](images/encryption-key.gif)

## Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
* kafka1
* kafka2
* kafka3
* kafka-client
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
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_MODE: VCLUSTER
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
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
    image: harbor.cdkt.dev/conduktor/conduktor-gateway
    hostname: gateway2
    container_name: gateway2
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_MODE: VCLUSTER
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_START_PORT: 7969
      GATEWAY_FEATURE_FLAGS_MULTI_TENANCY: true
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
 Network encryption-key_default  Creating
 Network encryption-key_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container kafka-client  Created
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka1  Creating
 Container kafka2  Creating
 Container kafka3  Created
 Container kafka2  Created
 Container kafka1  Created
 Container gateway1  Creating
 Container schema-registry  Creating
 Container gateway2  Creating
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container zookeeper  Starting
 Container kafka-client  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container kafka-client  Started
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container kafka1  Started
 Container kafka2  Started
 Container kafka3  Started
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container gateway1  Starting
 Container kafka3  Healthy
 Container schema-registry  Starting
 Container kafka3  Healthy
 Container gateway2  Starting
 Container schema-registry  Started
 Container gateway1  Started
 Container gateway2  Started
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container zookeeper  Healthy
 Container kafka-client  Healthy
 Container kafka2  Healthy
 Container gateway1  Healthy
 Container schema-registry  Healthy
 Container gateway2  Healthy

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-04-DOCKER.gif)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxODc4MTMwNX0.1QuhnCygSG-ZtzYKMPDrLrKhLg_9Jx1egQC7ifnVpf4';


```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-05-CREATE_VIRTUAL_CLUSTER.gif)

</details>

## Review the kafka properties to connect to `teamA`

Review the kafka properties to connect to `teamA`

```sh
cat teamA-sa.properties
```

<details open>
<summary>File content</summary>

```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxODc4MTIzOX0.MYfbnd9v3hppPbLgF8JWT3NowiUCUSXUhgjxwuF9Hxw';
bootstrap.servers=localhost:6969
```

</details>

## Creating topics customers-full-payload-level-encryption,customers-fields-level-encryption on teamA

Creating on `teamA`:

* Topic `customers-full-payload-level-encryption` with partitions:1 and replication-factor:1
* Topic `customers-fields-level-encryption` with partitions:1 and replication-factor:1

<details>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic customers-full-payload-level-encryption
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic customers-fields-level-encryption
```



</details>
<details>
<summary>Output</summary>

```
Created topic customers-full-payload-level-encryption.
Created topic customers-fields-level-encryption.

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-07-CREATE_TOPICS.gif)

</details>

## Adding interceptor field level encryption

Let's add the encryption interceptor to encrypt fields for key

Creating the interceptor named `field level encryption` of the plugin `io.conduktor.gateway.interceptor.EncryptPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.EncryptPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "customers-fields-level-encryption",
    "recordKey" : {
      "fields" : [ {
        "fieldName" : "password",
        "keySecretId" : "password-secret",
        "algorithm" : {
          "type" : "AES_GCM",
          "kms" : "IN_MEMORY"
        }
      }, {
        "fieldName" : "visa",
        "keySecretId" : "visa-secret",
        "algorithm" : {
          "type" : "AES_GCM",
          "kms" : "IN_MEMORY"
        }
      } ]
    }
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-08-field level encryption.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/field level encryption" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-field level encryption.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
cat: step-08-field: No such file or directory
cat: level: No such file or directory
cat: encryption.json: No such file or directory
curl: option --data: error encountered when reading a file
curl: try 'curl --help' for more information

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-08-ADD_INTERCEPTOR.gif)

</details>

## Adding interceptor full payload level encryption

Let's add the encryption interceptor to encrypt full payload for key

Creating the interceptor named `full payload level encryption` of the plugin `io.conduktor.gateway.interceptor.EncryptPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.EncryptPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "customers-full-payload-level-encryption",
    "recordKey" : {
      "payload" : {
        "keySecretId" : "payload-secret",
        "algorithm" : {
          "type" : "AES_GCM",
          "kms" : "IN_MEMORY"
        }
      }
    }
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-09-full payload level encryption.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/full payload level encryption" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-09-full payload level encryption.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
cat: step-09-full: No such file or directory
cat: payload: No such file or directory
cat: level: No such file or directory
cat: encryption.json: No such file or directory
curl: option --data: error encountered when reading a file
curl: try 'curl --help' for more information

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-09-ADD_INTERCEPTOR.gif)

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
  "interceptors": []
}

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-10-LIST_INTERCEPTORS.gif)

</details>

## Let's send unencrypted json to customers-fields-level-encryption topic

We are using regular kafka tools

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "key" : "{\"name\":\"tom\",\"username\":\"tom@conduktor.io\",\"password\":\"motorhead\",\"visa\":\"#abc123\",\"address\":\"Chancery lane, London\"}",
  "value" : {
    "msg" : "test msg"
  }
}
```
with


```sh
echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}\t{"msg": "test msg"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --property "parse.key=true" \
        --topic customers-fields-level-encryption
```



</details>
<details>
<summary>Output</summary>

```
step-11-PRODUCE-OUTPUT
```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-11-PRODUCE.gif)

</details>

## Let's send unencrypted json to customers-full-payload-level-encryption topic

We are using regular kafka tools

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "key" : "{\"name\":\"tom\",\"username\":\"tom@conduktor.io\",\"password\":\"motorhead\",\"visa\":\"#abc123\",\"address\":\"Chancery lane, London\"}",
  "value" : {
    "msg" : "test msg"
  }
}
```
with


```sh
echo '{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}\t{"msg": "test msg"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --property "parse.key=true" \
        --topic customers-full-payload-level-encryption
```



</details>
<details>
<summary>Output</summary>

```
step-12-PRODUCE-OUTPUT
```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-12-PRODUCE.gif)

</details>

## Let's consume the message, and confirm `tom` data is encrypted in customers-fields-level-encryption topic

Let's consume the message, and confirm `tom` data is encrypted in customers-fields-level-encryption topic in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-fields-level-encryption \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 1 event
```json
{
  "msg" : "test msg"
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-03-21 14:15:20,930] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "msg": "test msg"
}

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-13-CONSUME.gif)

</details>

## Let's consume the message, and confirm the entire `tom` message is encrypted in customers-full-payload-level-encryption topic

Let's consume the message, and confirm the entire `tom` message is encrypted in customers-full-payload-level-encryption topic in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-full-payload-level-encryption \
    --from-beginning \
    --timeout-ms 10000 | jq
```


returns 1 event
```json
{
  "msg" : "test msg"
}
```



</details>
<details>
<summary>Output</summary>

```json
[2024-03-21 14:15:32,143] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
{
  "msg": "test msg"
}

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-14-CONSUME.gif)

</details>

## Adding interceptor decrypt

Let's add the decrypt interceptor to decipher message

Creating the interceptor named `decrypt` of the plugin `io.conduktor.gateway.interceptor.DecryptPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.DecryptPlugin",
  "priority" : 100,
  "config" : {
    "topic" : ".*",
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

<details open>
<summary>Command</summary>



```sh
cat step-15-decrypt.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/decrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-15-decrypt.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
  "priority": 100,
  "config": {
    "topic": ".*",
    "kmsConfig": {
      "vault": {
        "uri": "http://vault:8200",
        "token": "vault-plaintext-root-token",
        "version": 1
      }
    }
  }
}
{
  "message": "decrypt is created"
}

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-15-ADD_INTERCEPTOR.gif)

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
      "name": "decrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "topic": ".*",
        "kmsConfig": {
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

![](images/encryption-key-step-16-LIST_INTERCEPTORS.gif)

</details>

## Confirm message from `tom` is decrypted in customers-fields-level-encryption topic

Confirm message from `tom` is decrypted in customers-fields-level-encryption topic in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-fields-level-encryption \
    --from-beginning \
    --timeout-ms 10000 \
    --property print.headers=true | jq
```


returns 1 event
```json
{
  "headers" : { },
  "value" : {
    "msg" : "test msg"
  }
}
```



</details>
<details>
<summary>Output</summary>

```json
jq: parse error: Invalid numeric literal at line 1, column 11
[2024-03-21 14:15:43,629] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-17-CONSUME.gif)

</details>

## Confirm message from `tom` is decrypted in customers-full-payload-level-encryption topic

Confirm message from `tom` is decrypted in customers-full-payload-level-encryption topic in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic customers-full-payload-level-encryption \
    --from-beginning \
    --timeout-ms 10000 \
    --property print.headers=true | jq
```


returns 1 event
```json
{
  "headers" : { },
  "value" : {
    "msg" : "test msg"
  }
}
```



</details>
<details>
<summary>Output</summary>

```json
jq: parse error: Invalid numeric literal at line 1, column 11
[2024-03-21 14:15:54,908] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-18-CONSUME.gif)

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
 Container gateway2  Stopping
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
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka-client  Stopped
 Container kafka-client  Removing
 Container kafka-client  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network encryption-key_default  Removing
 Network encryption-key_default  Removed

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-key-step-19-DOCKER.gif)

</details>

# Conclusion

Yes, encryption in the Kafka world can be simple!

