# Schema based field level encryption with Schema Registry

Yes, it work with Avro, Json Schema with nested fields

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

![](images/encryption-schema-based.gif)

## Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
* kafka1
* kafka2
* kafka3
* kafka-client
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
    image: harbor.cdkt.dev/conduktor/conduktor-gateway
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
 Network encryption-schema-based_default  Creating
 Network encryption-schema-based_default  Created
 Container kafka-client  Creating
 Container vault  Creating
 Container zookeeper  Creating
 Container kafka-client  Created
 Container vault  Created
 Container zookeeper  Created
 Container kafka1  Creating
 Container kafka2  Creating
 Container kafka3  Creating
 Container kafka3  Created
 Container kafka1  Created
 Container kafka2  Created
 Container gateway1  Creating
 Container schema-registry  Creating
 Container gateway2  Creating
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container vault  Starting
 Container zookeeper  Starting
 Container kafka-client  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container kafka-client  Started
 Container vault  Started
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container kafka3  Started
 Container kafka2  Started
 Container kafka1  Started
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway2  Starting
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container gateway2  Started
 Container gateway1  Started
 Container schema-registry  Started
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container vault  Waiting
 Container kafka1  Waiting
 Container zookeeper  Waiting
 Container kafka2  Waiting
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka-client  Healthy
 Container kafka2  Healthy
 Container vault  Healthy
 Container zookeeper  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-schema-based-step-04-DOCKER.gif)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxODc4MTc1NH0.5_agkJtLM8tjSsMDzrfCIDZHMhobfbsTb2bLQvR7gLk';


```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-schema-based-step-05-CREATE_VIRTUAL_CLUSTER.gif)

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

![](images/encryption-schema-based-step-06-CREATE_TOPICS.gif)

</details>

## Adding interceptor encrypt

We want to encrypt two fields at the root layer, and `location` in the `address` object. 
Here we are using an in memory KMS.

Creating the interceptor named `encrypt` of the plugin `io.conduktor.gateway.interceptor.EncryptSchemaBasedPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.EncryptSchemaBasedPlugin",
  "priority" : 100,
  "config" : {
    "kmsConfig" : {
      "vault" : {
        "uri" : "http://vault:8200",
        "token" : "vault-plaintext-root-token",
        "version" : 1
      }
    },
    "schemaRegistryConfig" : {
      "host" : "http://schema-registry:8081"
    },
    "defaultKeySecretId" : "myDefaultKeySecret",
    "defaultAlgorithm" : {
      "type" : "TINK/AES128_EAX",
      "kms" : "IN_MEMORY"
    },
    "tags" : [ "PII", "ENCRYPTION" ],
    "namespace" : "conduktor."
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-07-encrypt.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/encrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-07-encrypt.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.EncryptSchemaBasedPlugin",
  "priority": 100,
  "config": {
    "kmsConfig": {
      "vault": {
        "uri": "http://vault:8200",
        "token": "vault-plaintext-root-token",
        "version": 1
      }
    },
    "schemaRegistryConfig": {
      "host": "http://schema-registry:8081"
    },
    "defaultKeySecretId": "myDefaultKeySecret",
    "defaultAlgorithm": {
      "type": "TINK/AES128_EAX",
      "kms": "IN_MEMORY"
    },
    "tags": [
      "PII",
      "ENCRYPTION"
    ],
    "namespace": "conduktor."
  }
}
{
  "message": "encrypt is created"
}

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-schema-based-step-07-ADD_INTERCEPTOR.gif)

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
      "name": "encrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.EncryptSchemaBasedPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "kmsConfig": {
          "vault": {
            "uri": "http://vault:8200",
            "token": "vault-plaintext-root-token",
            "version": 1
          }
        },
        "schemaRegistryConfig": {
          "host": "http://schema-registry:8081"
        },
        "defaultKeySecretId": "myDefaultKeySecret",
        "defaultAlgorithm": {
          "type": "TINK/AES128_EAX",
          "kms": "IN_MEMORY"
        },
        "tags": [
          "PII",
          "ENCRYPTION"
        ],
        "namespace": "conduktor."
      }
    }
  ]
}

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-schema-based-step-08-LIST_INTERCEPTORS.gif)

</details>

## Let's send unencrypted json schema message with specified json schema with custom constrains for encryption



<details>
<summary>Command</summary>



```sh
valueSchema=$(echo '{
    "title": "Customer",
    "type": "object",
    "properties": {
      "name": { "type": "string" },
      "username": { "type": "string" },
      "password": { "type": "string", "conduktor.keySecretId": "password-secret", "conduktor.algorithm.type": "AES_GCM", "conduktor.algorithm.kms": "IN_MEMORY" },
      "visa": { "type": "string", "conduktor.keySecretId": "conduktor.visa-secret", "algorithm.type": "AES_GCM", "conduktor.algorithm.kms": "IN_MEMORY" },
      "address": {
        "type": "object",
        "properties": {
          "location": { "type": "string", "conduktor.tags": ["MY_TAG", "PII", "GDPR", "MY_OTHER_TAG"] },
          "town": { "type": "string" },
          "country": { "type": "string" }
        }
      }
    }
}' | jq -c)

keySchema=$(echo '{
    "title": "Metadata",
    "type": "object",
    "properties": {
        "sessionId": {"type": "string"},
        "authenticationToken": {"type": "string", "conduktor.keySecretId": "token-secret"},
        "deviceInformation": {"type": "string", "conduktor.algorithm": "AES128_CTR_HMAC_SHA256" }
    }
}' | jq -c)

invalidKeyTom=$(echo '{
        "sessionId": "session-id-tom",
        "authenticationToken": "authentication-token-tom",
        "deviceInformation": "device-information-tom"
    }' | jq -c)

invalidValueTom=$(echo '{
        "name": "tom",
        "username": "tom@conduktor.io",
        "password": "motorhead",
        "visa": "#abc123",
        "address": {
          "location": "12 Chancery lane",
          "town": "London",
          "country": "UK"
        }
    }' | jq -c)

invalidInputTom="$invalidKeyTom|$invalidValueTom"
echo $invalidInputTom | \
kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers \
        --property schema.registry.url=http://localhost:8081 \
        --property parse.key=true \
        --property key.separator="|" \
        --property value.schema=$valueSchema \
        --property key.schema=$keySchema 2>&1 /dev/null

invalidKeyLaura=$(echo '{
        "sessionId": "session-id-laura",
        "authenticationToken": "authentication-token-laura",
        "deviceInformation": "device-information-laura"
    }' | jq -c)

invalidValueLaura=$(echo '{
        "name": "laura",
        "username": "laura@conduktor.io",
        "password": "kitesurf",
        "visa": "#888999XZ;",
        "address": {
          "location": "4th Street, Jumeirah",
          "town": "Dubai",
          "country": "UAE"
        }
    }' | jq -c)

invalidInputLaura="$invalidKeyLaura|$invalidValueLaura"
echo $invalidInputLaura | \
kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic customers \
        --property schema.registry.url=http://localhost:8081 \
        --property parse.key=true \
        --property key.separator="|" \
        --property value.schema=$valueSchema \
        --property key.schema=$keySchema 2>&1 /dev/null
```



</details>
<details>
<summary>Output</summary>

```
[2024-03-21 14:22:36,279] INFO KafkaJsonSchemaSerializerConfig values: 
	auto.register.schemas = true
	basic.auth.credentials.source = URL
	basic.auth.user.info = [hidden]
	bearer.auth.cache.expiry.buffer.seconds = 300
	bearer.auth.client.id = null
	bearer.auth.client.secret = null
	bearer.auth.credentials.source = STATIC_TOKEN
	bearer.auth.custom.provider.class = null
	bearer.auth.identity.pool.id = null
	bearer.auth.issuer.endpoint.url = null
	bearer.auth.logical.cluster = null
	bearer.auth.scope = null
	bearer.auth.scope.claim.name = scope
	bearer.auth.sub.claim.name = sub
	bearer.auth.token = [hidden]
	context.name.strategy = class io.confluent.kafka.serializers.context.NullContextNameStrategy
	http.connect.timeout.ms = 60000
	http.read.timeout.ms = 60000
	id.compatibility.strict = true
	json.default.property.inclusion = null
	json.fail.invalid.schema = true
	json.fail.unknown.properties = true
	json.indent.output = false
	json.oneof.for.nullables = true
	json.schema.spec.version = draft_7
	json.write.dates.iso8601 = false
	key.subject.name.strategy = class io.confluent.kafka.serializers.subject.TopicNameStrategy
	latest.cache.size = 1000
	latest.cache.ttl.sec = -1
	latest.compatibility.strict = true
	max.schemas.per.subject = 1000
	normalize.schemas = false
	proxy.host = 
	proxy.port = -1
	rule.actions = []
	rule.executors = []
	rule.service.loader.enable = true
	schema.format = null
	schema.reflection = false
	schema.registry.basic.auth.user.info = [hidden]
	schema.registry.ssl.cipher.suites = null
	schema.registry.ssl.enabled.protocols = [TLSv1.2, TLSv1.3]
	schema.registry.ssl.endpoint.identification.algorithm = https
	schema.registry.ssl.engine.factory.class = null
	schema.registry.ssl.key.password = null
	schema.registry.ssl.keymanager.algorithm = SunX509
	schema.registry.ssl.keystore.certificate.chain = null
	schema.registry.ssl.keystore.key = null
	schema.registry.ssl.keystore.location = null
	schema.registry.ssl.keystore.password = null
	schema.registry.ssl.keystore.type = JKS
	schema.registry.ssl.protocol = TLSv1.3
	schema.registry.ssl.provider = null
	schema.registry.ssl.secure.random.implementation = null
	schema.registry.ssl.trustmanager.algorithm = PKIX
	schema.registry.ssl.truststore.certificates = null
	schema.registry.ssl.truststore.location = null
	schema.registry.ssl.truststore.password = null
	schema.registry.ssl.truststore.type = JKS
	schema.registry.url = [http://localhost:8081]
	use.latest.version = false
	use.latest.with.metadata = null
	use.schema.id = -1
	value.subject.name.strategy = class io.confluent.kafka.serializers.subject.TopicNameStrategy
 (io.confluent.kafka.serializers.json.KafkaJsonSchemaSerializerConfig:370)
[2024-03-21 14:22:37,997] INFO KafkaJsonSchemaSerializerConfig values: 
	auto.register.schemas = true
	basic.auth.credentials.source = URL
	basic.auth.user.info = [hidden]
	bearer.auth.cache.expiry.buffer.seconds = 300
	bearer.auth.client.id = null
	bearer.auth.client.secret = null
	bearer.auth.credentials.source = STATIC_TOKEN
	bearer.auth.custom.provider.class = null
	bearer.auth.identity.pool.id = null
	bearer.auth.issuer.endpoint.url = null
	bearer.auth.logical.cluster = null
	bearer.auth.scope = null
	bearer.auth.scope.claim.name = scope
	bearer.auth.sub.claim.name = sub
	bearer.auth.token = [hidden]
	context.name.strategy = class io.confluent.kafka.serializers.context.NullContextNameStrategy
	http.connect.timeout.ms = 60000
	http.read.timeout.ms = 60000
	id.compatibility.strict = true
	json.default.property.inclusion = null
	json.fail.invalid.schema = true
	json.fail.unknown.properties = true
	json.indent.output = false
	json.oneof.for.nullables = true
	json.schema.spec.version = draft_7
	json.write.dates.iso8601 = false
	key.subject.name.strategy = class io.confluent.kafka.serializers.subject.TopicNameStrategy
	latest.cache.size = 1000
	latest.cache.ttl.sec = -1
	latest.compatibility.strict = true
	max.schemas.per.subject = 1000
	normalize.schemas = false
	proxy.host = 
	proxy.port = -1
	rule.actions = []
	rule.executors = []
	rule.service.loader.enable = true
	schema.format = null
	schema.reflection = false
	schema.registry.basic.auth.user.info = [hidden]
	schema.registry.ssl.cipher.suites = null
	schema.registry.ssl.enabled.protocols = [TLSv1.2, TLSv1.3]
	schema.registry.ssl.endpoint.identification.algorithm = https
	schema.registry.ssl.engine.factory.class = null
	schema.registry.ssl.key.password = null
	schema.registry.ssl.keymanager.algorithm = SunX509
	schema.registry.ssl.keystore.certificate.chain = null
	schema.registry.ssl.keystore.key = null
	schema.registry.ssl.keystore.location = null
	schema.registry.ssl.keystore.password = null
	schema.registry.ssl.keystore.type = JKS
	schema.registry.ssl.protocol = TLSv1.3
	schema.registry.ssl.provider = null
	schema.registry.ssl.secure.random.implementation = null
	schema.registry.ssl.trustmanager.algorithm = PKIX
	schema.registry.ssl.truststore.certificates = null
	schema.registry.ssl.truststore.location = null
	schema.registry.ssl.truststore.password = null
	schema.registry.ssl.truststore.type = JKS
	schema.registry.url = [http://localhost:8081]
	use.latest.version = false
	use.latest.with.metadata = null
	use.schema.id = -1
	value.subject.name.strategy = class io.confluent.kafka.serializers.subject.TopicNameStrategy
 (io.confluent.kafka.serializers.json.KafkaJsonSchemaSerializerConfig:370)

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-schema-based-step-09-SH.gif)

</details>

## Let's make sure they are encrypted

password and visa and the nested field `address.location` are encrypted

<details open>
<summary>Command</summary>



```sh
kafka-json-schema-console-consumer \
  --bootstrap-server localhost:6969 \
  --consumer.config teamA-sa.properties \
  --property schema.registry.url=http://localhost:8081 \
  --property print.key=true \
  --topic customers \
  --from-beginning \
  --max-messages 2 2>&1  /dev/null | grep '{' | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "sessionId": "session-id-tom",
  "authenticationToken": "AAAABQAAAAEAAAA7AUM/orB6mpncj894CV7fq9tPM2qgiuknDdk/lfUoQMHp0DUBFaJJOJKK6s1FdNU7EItEUwfkCefwv+umksqSfAn/X4YoRg63H0WHJUAKya4CFXdEQDKYj0azV6g1NkA3abATDSb8ZflkfRTUntE5UwtVeGbUYXxDCmY=",
  "deviceInformation": "AAAABQAAAAEAAABnAfkvixSNMJqw5fI/eV0DusQhjpUO0PnrIn4/xGaWpB78yo0pAh7qMUAZ8VCLEAXt9Lh9dOTC2juzwJsHS9Tb/BGaA5KFTOqbXsR59F+fozeGYSr7DiScbmCjfUkIBrVrCLzTmP+XA2rWdMPZ1RhtOJBFmMXJ9sha1c5KsuUgB151BN7szYG3XROmdzSBjrVMz4tqSp8hbQKjXQlDmYHZyixFOcw="
}
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "AAAABQAAAAEAAAAzAVc196GA0eaQ8sYAomzeiPQv+gE9ROTzMdorA8Qvn6vsR0VEXE5t42IhLlw89tJbPNGvWtInEEEOJx/Xi7Wma/okNagEbwxRd8lxjKGYnwnS61H+rI4yzcB0V+zLtw4=",
  "visa": "AAAABQAAAAEAAAA7AUpGublvbZ/vgLz7jjTcBeUA0m+how0uo8nzF+TqTVt99q1ODy44vJ7ObpRUVA0TyVY15oAXLQAf1l3MosJpDxjW5fDhJSIZkCpRuU8m+rwXJrWQO9dLBhrDC+D5XeHHMSGQOZAqyE6i",
  "address": {
    "location": "AAAABQAAAAEAAAA7AfkvixTy4QejoPMh9Vacz0cDNS1Bfk/m7ZJyYLFAxGjfaJXVpICEI3U/CkYnv4wfEUmTrX5kEAXUBOo1ssGl+KDTOgToPuCJ9GeDircExi71ZR2dsAoQIoHf/m1Mwkj3qr1LgoTbeWTSNb+L3C+kIeqZ",
    "town": "London",
    "country": "UK"
  }
}
{
  "sessionId": "session-id-laura",
  "authenticationToken": "AAAABQAAAAEAAAA7AUM/orB6mpncj894CV7fq9tPM2qgiuknDdk/lfUoQMHp0DUBFaJJOJKK6s1FdNU7EItEUwfkCefwv+sVllZyjYNkZ38yXhbL7BRMnBPR9KbYP5aybbwjZV1BJKN6BN36ywz0T6nLy2wZ4fjMrdrAZuZGfxBvkBJqQ4smVw==",
  "deviceInformation": "AAAABQAAAAEAAABnAfkvixSNMJqw5fI/eV0DusQhjpUO0PnrIn4/xGaWpB78yo0pAh7qMUAZ8VCLEAXt9Lh9dOTC2juzwJsHS9Tb/BGaA5KFTOqbXsR59F+fozeGYSr7DiScbmCjfUkIBrVrCLzTmP+XA5vYHu5bZopREHoYd/G/HD/08JsrTqgqJzM0Jwq75vkLXs1beZvpBX+cD8Dge9Tc/3XNCeh1jj4sXCK8hVQ9kA=="
}
{
  "name": "laura",
  "username": "laura@conduktor.io",
  "password": "AAAABQAAAAEAAAAzAVc196GA0eaQ8sYAomzeiPQv+gE9ROTzMdorA8Qvn6vsR0VEXE5t42IhLlw89tJbPNGvJYI7vhs4IZH/wOpSSPhDtOyw4UpfWHfSl2FwOnJIBsPyLRWrFC2Q6rPJog==",
  "visa": "AAAABQAAAAEAAAA7AUpGublvbZ/vgLz7jjTcBeUA0m+how0uo8nzF+TqTVt99q1ODy44vJ7ObpRUVA0TyVY15oAXLQAf1l383eYPMWXJ4QNIjPQIylaOaQyp+iJMPU14yg+gj3t1b3+gi5+7LBnGfqOhgu+KCdas",
  "address": {
    "location": "AAAABQAAAAEAAAA7AfkvixTy4QejoPMh9Vacz0cDNS1Bfk/m7ZJyYLFAxGjfaJXVpICEI3U/CkYnv4wfEUmTrX5kEAXUBOq9IJ+2QddPB1gdm4SQPMkdcvgcaJQbEPA6KXMvzQ2xZBjNQFxz1AzD1CjvmSOAOtTXvf8Mr9JDSR3gOg==",
    "town": "Dubai",
    "country": "UAE"
  }
}

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-schema-based-step-10-SH.gif)

</details>

## Adding interceptor decrypt

Let's add the decrypt interceptor to decipher messages

Creating the interceptor named `decrypt` of the plugin `io.conduktor.gateway.interceptor.DecryptPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.DecryptPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "customers",
    "schemaRegistryConfig" : {
      "host" : "http://schema-registry:8081"
    }
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-11-decrypt.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/decrypt" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-11-decrypt.json | jq
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
    "schemaRegistryConfig": {
      "host": "http://schema-registry:8081"
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

![](images/encryption-schema-based-step-11-ADD_INTERCEPTOR.gif)

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
      "name": "encrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.EncryptSchemaBasedPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "kmsConfig": {
          "vault": {
            "uri": "http://vault:8200",
            "token": "vault-plaintext-root-token",
            "version": 1
          }
        },
        "schemaRegistryConfig": {
          "host": "http://schema-registry:8081"
        },
        "defaultKeySecretId": "myDefaultKeySecret",
        "defaultAlgorithm": {
          "type": "TINK/AES128_EAX",
          "kms": "IN_MEMORY"
        },
        "tags": [
          "PII",
          "ENCRYPTION"
        ],
        "namespace": "conduktor."
      }
    },
    {
      "name": "decrypt",
      "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "topic": "customers",
        "schemaRegistryConfig": {
          "host": "http://schema-registry:8081"
        }
      }
    }
  ]
}

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-schema-based-step-12-LIST_INTERCEPTORS.gif)

</details>

## Let's make sure they are decrypted

password and visa and the nested field `address.location` are decrypted

<details open>
<summary>Command</summary>



```sh
kafka-json-schema-console-consumer \
  --bootstrap-server localhost:6969 \
  --consumer.config teamA-sa.properties \
  --property schema.registry.url=http://localhost:8081 \
  --property print.key=true \
  --topic customers \
  --from-beginning \
  --max-messages 2 2>&1 | grep '{' | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "sessionId": "session-id-tom",
  "authenticationToken": "authentication-token-tom",
  "deviceInformation": "device-information-tom"
}
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "motorhead",
  "visa": "#abc123",
  "address": {
    "location": "12 Chancery lane",
    "town": "London",
    "country": "UK"
  }
}
{
  "sessionId": "session-id-laura",
  "authenticationToken": "authentication-token-laura",
  "deviceInformation": "device-information-laura"
}
{
  "name": "laura",
  "username": "laura@conduktor.io",
  "password": "kitesurf",
  "visa": "#888999XZ;",
  "address": {
    "location": "4th Street, Jumeirah",
    "town": "Dubai",
    "country": "UAE"
  }
}

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-schema-based-step-13-SH.gif)

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
 Container schema-registry  Stopping
 Container kafka-client  Stopping
 Container gateway1  Stopping
 Container gateway2  Stopping
 Container vault  Stopping
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
 Container kafka2  Stopping
 Container kafka3  Stopping
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
 Network encryption-schema-based_default  Removing
 Network encryption-schema-based_default  Removed

```

</details>
<details>
<summary>Recording</summary>

![](images/encryption-schema-based-step-14-DOCKER.gif)

</details>

# Conclusion

Yes, encryption in the Kafka world can be simple!

