# What is a Schema Payload Validation Policy Interceptor?

Avoid outages from missing or badly formatted records, ensure all messages adhere to a schema.

This interceptor also supports validating payload against specific constraints for AvroSchema and ProtoBuf

This is similar to the validations provided by JsonSchema, such as:

- **Number**: `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`, `multipleOf`
- **String**: `minLength`, `maxLength`, `pattern`, `format`
- **Collections**: `maxItems`, `minItems`

## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/9mSt4363KEnqXL21woEL7BBf1.svg)](https://asciinema.org/a/9mSt4363KEnqXL21woEL7BBf1)

### Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
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
networks:
  demo: null
```

</details>

 <details>
  <summary>docker compose ps</summary>

```
NAME              IMAGE                                    COMMAND                  SERVICE           CREATED          STATUS                    PORTS
gateway1          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway1          28 seconds ago   Up 15 seconds (healthy)   0.0.0.0:6969-6971->6969-6971/tcp, 0.0.0.0:8888->8888/tcp
gateway2          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway2          28 seconds ago   Up 15 seconds (healthy)   0.0.0.0:7969-7971->7969-7971/tcp, 0.0.0.0:8889->8888/tcp
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            28 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            28 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
kafka3            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka3            28 seconds ago   Up 21 seconds (healthy)   9092/tcp, 0.0.0.0:19094->19094/tcp
schema-registry   confluentinc/cp-schema-registry:latest   "/etc/confluent/dock…"   schema-registry   28 seconds ago   Up 15 seconds (healthy)   0.0.0.0:8081->8081/tcp
zookeeper         confluentinc/cp-zookeeper:latest         "/etc/confluent/dock…"   zookeeper         28 seconds ago   Up 27 seconds (healthy)   2181/tcp, 2888/tcp, 3888/tcp

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
 Network safeguard-validate-schema-payload-json_default  Creating
 Network safeguard-validate-schema-payload-json_default  Created
 Container zookeeper  Creating
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
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container zookeeper  Starting
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
 Container kafka1  Started
 Container kafka2  Started
 Container kafka3  Started
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container schema-registry  Starting
 Container kafka3  Healthy
 Container gateway2  Starting
 Container schema-registry  Started
 Container gateway2  Started
 Container gateway1  Started
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container zookeeper  Healthy
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
      


### Review the kafka properties to connect to `teamA`

Review the kafka properties to connect to `teamA`

```sh
cat teamA-sa.properties
```

<details on>
  <summary>File content</summary>

```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzc0NDg0NX0.76biy0ULdNE4zSrHS0Gu3-1-HYh5av-1uYyi2kh_5uM';
bootstrap.servers=localhost:6969
```

</details>


## Creating topic `topic-json-schema` on `teamA`

Creating topic `topic-json-schema` on `teamA`
* Topic `topic-json-schema` with partitions:1 and replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic topic-json-schema
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `topic-json-schema` on `teamA`](images/step-07-CREATE_TOPICS.gif)

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
    --topic topic-json-schema
Created topic topic-json-schema.

```

</details>
      


### Review the example json schema schema

Review the example json schema schema

```sh
cat user-schema-with-validation-rules.json
```

<details>
  <summary>File content</summary>

```json
{
  "$id":"https://example.com/user-schema.json",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "minLength": 3,
      "maxLength": 50
    },
    "age": {
      "type": "integer",
      "minimum": 0,
      "maximum": 120
    },
    "email": {
      "type": "string",
      "format": "email"
    },
    "address": {
      "type": "object",
      "properties": {
        "street": {
          "type": "string",
          "minLength": 5,
          "maxLength": 15
        },
        "city": {
          "type": "string",
          "minLength": 2,
          "maxLength": 50
        }
      }
    },
    "hobbies": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 2
    }
  }
}
```

</details>


## Let's register it to the Schema Registry



```sh
curl -s \
  http://localhost:8081/subjects/topic-json-schema/versions \
  -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data "{\"schemaType\": \"JSON\", \"schema\": $(cat user-schema-with-validation-rules.json | jq tostring)}"
```

<details>
  <summary>Realtime command output</summary>

  ![Let's register it to the Schema Registry](images/step-09-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

curl -s \
  http://localhost:8081/subjects/topic-json-schema/versions \
  -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data "{\"schemaType\": \"JSON\", \"schema\": $(cat user-schema-with-validation-rules.json | jq tostring)}"
cat user-schema-with-validation-rules.json | jq tostring
{"id":1}
```

</details>
      


### Review invalid payload

Review invalid payload

```sh
cat invalid-payload.json
```

<details>
  <summary>File content</summary>

```json
{
  "name": "D",
  "age": 17,
  "email": "bad email",
  "address": {
    "street": "a way too lond adress that will not fit in your database",
    "city": ""
  },
  "hobbies": [
    "reading"
  ],
  "friends": [
    {
      "name": "Tom",
      "age": 17
    },
    {
      "name": "Emma",
      "age": 18
    }
  ]
}
```

</details>


## Let's send invalid data

Perfect the Json Schema serializer did its magic and validated our rules

```sh
cat invalid-payload.json | jq -c | \
    kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-json-schema \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=1
```

<details>
  <summary>Realtime command output</summary>

  ![Let's send invalid data](images/step-11-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat invalid-payload.json | jq -c | \
    kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-json-schema \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=1
[2024-01-23 01:15:22,748] INFO KafkaJsonSchemaSerializerConfig values: 
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
 (io.confluent.kafka.serializers.json.KafkaJsonSchemaSerializerConfig:376)
org.apache.kafka.common.errors.SerializationException: Error serializing JSON message
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaSerializer.serializeImpl(AbstractKafkaJsonSchemaSerializer.java:166)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageReader$JsonSchemaMessageSerializer.serialize(JsonSchemaMessageReader.java:167)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageReader$JsonSchemaMessageSerializer.serialize(JsonSchemaMessageReader.java:130)
	at io.confluent.kafka.formatter.SchemaMessageReader.readMessage(SchemaMessageReader.java:406)
	at kafka.tools.ConsoleProducer$.main(ConsoleProducer.scala:50)
	at kafka.tools.ConsoleProducer.main(ConsoleProducer.scala)
Caused by: org.apache.kafka.common.errors.SerializationException: Validation error in JSON {"name":"D","age":17,"email":"bad email","address":{"street":"a way too lond adress that will not fit in your database","city":""},"hobbies":["reading"],"friends":[{"name":"Tom","age":17},{"name":"Emma","age":18}]}, Error report:
{
  "schemaLocation": "#",
  "pointerToViolation": "#",
  "causingExceptions": [
    {
      "schemaLocation": "#/properties/address",
      "pointerToViolation": "#/address",
      "causingExceptions": [
        {
          "schemaLocation": "#/properties/address/properties/city",
          "pointerToViolation": "#/address/city",
          "causingExceptions": [],
          "keyword": "minLength",
          "message": "expected minLength: 2, actual: 0"
        },
        {
          "schemaLocation": "#/properties/address/properties/street",
          "pointerToViolation": "#/address/street",
          "causingExceptions": [],
          "keyword": "maxLength",
          "message": "expected maxLength: 15, actual: 56"
        }
      ],
      "message": "2 schema violations found"
    },
    {
      "schemaLocation": "#/properties/hobbies",
      "pointerToViolation": "#/hobbies",
      "causingExceptions": [],
      "keyword": "minItems",
      "message": "expected minimum item count: 2, found: 1"
    },
    {
      "schemaLocation": "#/properties/name",
      "pointerToViolation": "#/name",
      "causingExceptions": [],
      "keyword": "minLength",
      "message": "expected minLength: 3, actual: 1"
    },
    {
      "schemaLocation": "#/properties/email",
      "pointerToViolation": "#/email",
      "causingExceptions": [],
      "keyword": "format",
      "message": "[bad email] is not a valid email address"
    }
  ],
  "message": "5 schema violations found"
}
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaSerializer.validateJson(AbstractKafkaJsonSchemaSerializer.java:189)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaSerializer.serializeImpl(AbstractKafkaJsonSchemaSerializer.java:154)
	... 5 more
Caused by: org.everit.json.schema.ValidationException: #: 5 schema violations found
	at org.everit.json.schema.ValidationException.copy(ValidationException.java:486)
	at org.everit.json.schema.DefaultValidator.performValidation(Validator.java:76)
	at org.everit.json.schema.Schema.validate(Schema.java:152)
	at io.confluent.kafka.schemaregistry.json.JsonSchema.validate(JsonSchema.java:441)
	at io.confluent.kafka.schemaregistry.json.JsonSchema.validate(JsonSchema.java:409)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaSerializer.validateJson(AbstractKafkaJsonSchemaSerializer.java:179)
	... 6 more

```

</details>
      


## Let's send invalid data using the protocol

Unfortunately the message went through

```sh
MAGIC_BYTE="\x00"
SCHEMA_ID="\x00\x00\x00\x01"
JSON_PAYLOAD=$(cat invalid-payload.json | jq -c)
printf "${MAGIC_BYTE}${SCHEMA_ID}${JSON_PAYLOAD}" | \
  kcat \
    -b  localhost:6969 \
    -X security.protocol=SASL_PLAINTEXT \
    -X sasl.mechanism=PLAIN \
    -X sasl.username=sa \
    -X sasl.password=$(cat teamA-sa.properties | awk -F"'" '/password=/{print $4}') \
    -P \
    -t topic-json-schema
```

<details>
  <summary>Realtime command output</summary>

  ![Let's send invalid data using the protocol](images/step-12-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

MAGIC_BYTE="\x00"
SCHEMA_ID="\x00\x00\x00\x01"
JSON_PAYLOAD=$(cat invalid-payload.json | jq -c)
cat invalid-payload.json | jq -c
printf "${MAGIC_BYTE}${SCHEMA_ID}${JSON_PAYLOAD}" | \
  kcat \
    -b  localhost:6969 \
    -X security.protocol=SASL_PLAINTEXT \
    -X sasl.mechanism=PLAIN \
    -X sasl.username=sa \
    -X sasl.password=$(cat teamA-sa.properties | awk -F"'" '/password=/{print $4}') \
    -P \
    -t topic-json-schema
cat teamA-sa.properties | awk -F"'" '/password=/{print $4}'

```

</details>
      


## Let's consume it back

That's pretty bad, you are going to propagate wrong data within your system!

```sh
kafka-json-schema-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-json-schema \
    --from-beginning \
    --skip-message-on-error \
    --timeout-ms 3000
```

<details>
  <summary>Realtime command output</summary>

  ![Let's consume it back](images/step-13-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-json-schema-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-json-schema \
    --from-beginning \
    --skip-message-on-error \
    --timeout-ms 3000
[2024-01-23 01:15:24,355] INFO KafkaJsonSchemaDeserializerConfig values: 
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
	json.fail.invalid.schema = true
	json.fail.unknown.properties = true
	json.key.type = class java.lang.Object
	json.value.type = class java.lang.Object
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
	type.property = javaType
	use.latest.version = false
	use.latest.with.metadata = null
	use.schema.id = -1
	value.subject.name.strategy = class io.confluent.kafka.serializers.subject.TopicNameStrategy
 (io.confluent.kafka.serializers.json.KafkaJsonSchemaDeserializerConfig:376)
[2024-01-23 01:15:25,171] ERROR Error processing message, skipping this message:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.SerializationException: Error deserializing JSON message for id 1
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:236)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:135)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:101)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter.writeTo(JsonSchemaMessageFormatter.java:92)
	at io.confluent.kafka.formatter.SchemaMessageFormatter.writeTo(SchemaMessageFormatter.java:266)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:116)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:76)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:53)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Caused by: org.apache.kafka.common.errors.SerializationException: JSON {"name":"D","age":17,"email":"bad email","address":{"street":"a way too lond adress that will not fit in your database","city":""},"hobbies":["reading"],"friends":[{"name":"Tom","age":17},{"name":"Emma","age":18}]} does not match schema {"$id":"https://example.com/user-schema.json","$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"name":{"type":"string","minLength":3,"maxLength":50},"age":{"type":"integer","minimum":0,"maximum":120},"email":{"type":"string","format":"email"},"address":{"type":"object","properties":{"street":{"type":"string","minLength":5,"maxLength":15},"city":{"type":"string","minLength":2,"maxLength":50}}},"hobbies":{"type":"array","items":{"type":"string"},"minItems":2}}}
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:183)
	... 8 more
Caused by: org.everit.json.schema.ValidationException: #: 5 schema violations found
	at org.everit.json.schema.ValidationException.copy(ValidationException.java:486)
	at org.everit.json.schema.DefaultValidator.performValidation(Validator.java:76)
	at org.everit.json.schema.Schema.validate(Schema.java:152)
	at io.confluent.kafka.schemaregistry.json.JsonSchema.validate(JsonSchema.java:441)
	at io.confluent.kafka.schemaregistry.json.JsonSchema.validate(JsonSchema.java:409)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:178)
	... 8 more
[2024-01-23 01:15:25,171] ERROR Error processing message, skipping this message:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.SerializationException: Error deserializing JSON message for id 1
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:236)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:135)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:101)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter.writeTo(JsonSchemaMessageFormatter.java:92)
	at io.confluent.kafka.formatter.SchemaMessageFormatter.writeTo(SchemaMessageFormatter.java:266)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:116)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:76)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:53)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Caused by: org.apache.kafka.common.errors.SerializationException: JSON {"name":"D","age":17,"email":"bad email","address":{"street":"a way too lond adress that will not fit in your database","city":""},"hobbies":["reading"],"friends":[{"name":"Tom","age":17},{"name":"Emma","age":18}]} does not match schema {"$id":"https://example.com/user-schema.json","$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"name":{"type":"string","minLength":3,"maxLength":50},"age":{"type":"integer","minimum":0,"maximum":120},"email":{"type":"string","format":"email"},"address":{"type":"object","properties":{"street":{"type":"string","minLength":5,"maxLength":15},"city":{"type":"string","minLength":2,"maxLength":50}}},"hobbies":{"type":"array","items":{"type":"string"},"minItems":2}}}
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:183)
	... 8 more
Caused by: org.everit.json.schema.ValidationException: #: 5 schema violations found
	at org.everit.json.schema.ValidationException.copy(ValidationException.java:486)
	at org.everit.json.schema.DefaultValidator.performValidation(Validator.java:76)
	at org.everit.json.schema.Schema.validate(Schema.java:152)
	at io.confluent.kafka.schemaregistry.json.JsonSchema.validate(JsonSchema.java:441)
	at io.confluent.kafka.schemaregistry.json.JsonSchema.validate(JsonSchema.java:409)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:178)
	... 8 more
[2024-01-23 01:15:28,174] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.TimeoutException
[2024-01-23 01:15:28,174] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

```

</details>
      


## Adding interceptor `guard-schema-payload-validate`

Add Schema Payload Validation Policy Interceptor


Creating the interceptor named `guard-schema-payload-validate` of the plugin `io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin",
  "priority" : 100,
  "config" : {
    "schemaRegistryConfig" : {
      "host" : "http://schema-registry:8081"
    },
    "topic" : "topic-.*",
    "schemaIdRequired" : true,
    "validateSchema" : true,
    "action" : "BLOCK"
  }
}
```

Here's how to send it:

```sh
cat step-14-guard-schema-payload-validate.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-schema-payload-validate" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-14-guard-schema-payload-validate.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `guard-schema-payload-validate`](images/step-14-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-14-guard-schema-payload-validate.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin",
  "priority": 100,
  "config": {
    "schemaRegistryConfig": {
      "host": "http://schema-registry:8081"
    },
    "topic": "topic-.*",
    "schemaIdRequired": true,
    "validateSchema": true,
    "action": "BLOCK"
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-schema-payload-validate" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-14-guard-schema-payload-validate.json | jq
{
  "message": "guard-schema-payload-validate is created"
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

  ![Listing interceptors for `teamA`](images/step-15-LIST_INTERCEPTORS.gif)

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
      "name": "guard-schema-payload-validate",
      "pluginClass": "io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "schemaRegistryConfig": {
          "host": "http://schema-registry:8081"
        },
        "topic": "topic-.*",
        "schemaIdRequired": true,
        "validateSchema": true,
        "action": "BLOCK"
      }
    }
  ]
}

```

</details>
      


## Let's send invalid data using the protocol again

Perfect our interceptor did its magic and validated our rules

```sh
MAGIC_BYTE="\x00"
SCHEMA_ID="\x00\x00\x00\x01"
JSON_PAYLOAD=$(cat invalid-payload.json | jq -c)
printf "${MAGIC_BYTE}${SCHEMA_ID}${JSON_PAYLOAD}" | \
  kcat \
    -b  localhost:6969 \
    -X security.protocol=SASL_PLAINTEXT \
    -X sasl.mechanism=PLAIN \
    -X sasl.username=sa \
    -X sasl.password=$(cat teamA-sa.properties | awk -F"'" '/password=/{print $4}') \
    -P \
    -t topic-json-schema
```

<details>
  <summary>Realtime command output</summary>

  ![Let's send invalid data using the protocol again](images/step-16-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

MAGIC_BYTE="\x00"
SCHEMA_ID="\x00\x00\x00\x01"
JSON_PAYLOAD=$(cat invalid-payload.json | jq -c)
cat invalid-payload.json | jq -c
printf "${MAGIC_BYTE}${SCHEMA_ID}${JSON_PAYLOAD}" | \
  kcat \
    -b  localhost:6969 \
    -X security.protocol=SASL_PLAINTEXT \
    -X sasl.mechanism=PLAIN \
    -X sasl.username=sa \
    -X sasl.password=$(cat teamA-sa.properties | awk -F"'" '/password=/{print $4}') \
    -P \
    -t topic-json-schema
cat teamA-sa.properties | awk -F"'" '/password=/{print $4}'
% Delivery failed for message: Broker: Policy violation

```

</details>
      


## Check in the audit log that message was denied

Check in the audit log that message was denied in cluster `kafka1`

```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin")'
```


```json
{
  "id" : "6efff7a5-3cf3-42e5-8ae9-21cadd8469a2",
  "source" : "krn://cluster=hkMNOWNfRHyC3Y32MRyI4Q",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:28349"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-01-23T00:14:13.893181382Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin",
    "message" : "Request parameters do not satisfy the configured policy. Topic 'topic-json-schema' has invalid json schema payload: [#/hobbies: expected minimum item count: 2, found: 1, #/name: expected minLength: 3, actual: 1, #/email: [bad email] is not a valid email address, #/address/city: expected minLength: 2, actual: 0, #/address/street: expected maxLength: 15, actual: 56]"
  }
}
```


<details>
  <summary>Realtime command output</summary>

  ![Check in the audit log that message was denied](images/step-17-AUDITLOG.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin")'
[2024-01-23 01:15:33,367] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 14 messages
{
  "id": "d1e471db-5b31-47ef-a2b1-9305d4c496d9",
  "source": "krn://cluster=lDdK_Y4rQRqw-gRUoD-XXA",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:28677"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-23T00:15:29.448555130Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin",
    "message": "Request parameters do not satisfy the configured policy. Topic 'topic-json-schema' has invalid json schema payload: [#/hobbies: expected minimum item count: 2, found: 1, #/name: expected minLength: 3, actual: 1, #/email: [bad email] is not a valid email address, #/address/city: expected minLength: 2, actual: 0, #/address/street: expected maxLength: 15, actual: 56]"
  }
}

```

</details>
      


## Let's now produce a valid payload



```sh
cat valid-payload.json | jq -c | \
    kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-json-schema \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=1
```

<details>
  <summary>Realtime command output</summary>

  ![Let's now produce a valid payload](images/step-18-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat valid-payload.json | jq -c | \
    kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-json-schema \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=1
[2024-01-23 01:15:34,390] INFO KafkaJsonSchemaSerializerConfig values: 
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
 (io.confluent.kafka.serializers.json.KafkaJsonSchemaSerializerConfig:376)

```

</details>
      


## And consume it back



```sh
kafka-json-schema-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-json-schema \
    --from-beginning \
    --skip-message-on-error \
    --timeout-ms 3000
```

<details>
  <summary>Realtime command output</summary>

  ![And consume it back](images/step-19-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-json-schema-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-json-schema \
    --from-beginning \
    --skip-message-on-error \
    --timeout-ms 3000
[2024-01-23 01:15:35,889] INFO KafkaJsonSchemaDeserializerConfig values: 
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
	json.fail.invalid.schema = true
	json.fail.unknown.properties = true
	json.key.type = class java.lang.Object
	json.value.type = class java.lang.Object
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
	type.property = javaType
	use.latest.version = false
	use.latest.with.metadata = null
	use.schema.id = -1
	value.subject.name.strategy = class io.confluent.kafka.serializers.subject.TopicNameStrategy
 (io.confluent.kafka.serializers.json.KafkaJsonSchemaDeserializerConfig:376)
[2024-01-23 01:15:36,536] ERROR Error processing message, skipping this message:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.SerializationException: Error deserializing JSON message for id 1
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:236)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:135)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:101)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter.writeTo(JsonSchemaMessageFormatter.java:92)
	at io.confluent.kafka.formatter.SchemaMessageFormatter.writeTo(SchemaMessageFormatter.java:266)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:116)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:76)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:53)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Caused by: org.apache.kafka.common.errors.SerializationException: JSON {"name":"D","age":17,"email":"bad email","address":{"street":"a way too lond adress that will not fit in your database","city":""},"hobbies":["reading"],"friends":[{"name":"Tom","age":17},{"name":"Emma","age":18}]} does not match schema {"$id":"https://example.com/user-schema.json","$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"name":{"type":"string","minLength":3,"maxLength":50},"age":{"type":"integer","minimum":0,"maximum":120},"email":{"type":"string","format":"email"},"address":{"type":"object","properties":{"street":{"type":"string","minLength":5,"maxLength":15},"city":{"type":"string","minLength":2,"maxLength":50}}},"hobbies":{"type":"array","items":{"type":"string"},"minItems":2}}}
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:183)
	... 8 more
Caused by: org.everit.json.schema.ValidationException: #: 5 schema violations found
	at org.everit.json.schema.ValidationException.copy(ValidationException.java:486)
	at org.everit.json.schema.DefaultValidator.performValidation(Validator.java:76)
	at org.everit.json.schema.Schema.validate(Schema.java:152)
	at io.confluent.kafka.schemaregistry.json.JsonSchema.validate(JsonSchema.java:441)
	at io.confluent.kafka.schemaregistry.json.JsonSchema.validate(JsonSchema.java:409)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:178)
	... 8 more
[2024-01-23 01:15:36,536] ERROR Error processing message, skipping this message:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.SerializationException: Error deserializing JSON message for id 1
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:236)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:135)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:101)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter.writeTo(JsonSchemaMessageFormatter.java:92)
	at io.confluent.kafka.formatter.SchemaMessageFormatter.writeTo(SchemaMessageFormatter.java:266)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:116)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:76)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:53)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Caused by: org.apache.kafka.common.errors.SerializationException: JSON {"name":"D","age":17,"email":"bad email","address":{"street":"a way too lond adress that will not fit in your database","city":""},"hobbies":["reading"],"friends":[{"name":"Tom","age":17},{"name":"Emma","age":18}]} does not match schema {"$id":"https://example.com/user-schema.json","$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"name":{"type":"string","minLength":3,"maxLength":50},"age":{"type":"integer","minimum":0,"maximum":120},"email":{"type":"string","format":"email"},"address":{"type":"object","properties":{"street":{"type":"string","minLength":5,"maxLength":15},"city":{"type":"string","minLength":2,"maxLength":50}}},"hobbies":{"type":"array","items":{"type":"string"},"minItems":2}}}
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:183)
	... 8 more
Caused by: org.everit.json.schema.ValidationException: #: 5 schema violations found
	at org.everit.json.schema.ValidationException.copy(ValidationException.java:486)
	at org.everit.json.schema.DefaultValidator.performValidation(Validator.java:76)
	at org.everit.json.schema.Schema.validate(Schema.java:152)
	at io.confluent.kafka.schemaregistry.json.JsonSchema.validate(JsonSchema.java:441)
	at io.confluent.kafka.schemaregistry.json.JsonSchema.validate(JsonSchema.java:409)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:178)
	... 8 more
{"name":"Doe","age":17,"email":"john.doe@example.com","address":{"street":"123 Main St","city":"Anytown"},"hobbies":["reading","cycling"],"friends":[{"name":"Tom","age":9},{"name":"Emma","age":10}]}
[2024-01-23 01:15:39,539] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.TimeoutException
[2024-01-23 01:15:39,539] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages

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

  ![Tearing down the docker environment](images/step-20-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose down --volumes
 Container gateway2  Stopping
 Container schema-registry  Stopping
 Container gateway1  Stopping
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
 Container kafka1  Stopping
 Container kafka2  Stopping
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
 Network safeguard-validate-schema-payload-json_default  Removing
 Network safeguard-validate-schema-payload-json_default  Removed

```

</details>
      


# Conclusion

You can enrich your existing schema to add even more data quality to your systems!

