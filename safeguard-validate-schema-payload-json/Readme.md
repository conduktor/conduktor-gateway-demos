# What is a Schema Payload Validation Policy Interceptor?

Avoid outages from missing or badly formatted records, ensure all messages adhere to a schema.

This interceptor also supports validating payload against specific constraints for AvroSchema and ProtoBuf

This is similar to the validations provided by JsonSchema, such as:

- **Number**: `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`, `multipleOf`
- **String**: `minLength`, `maxLength`, `pattern`, `format`
- **Collections**: `maxItems`, `minItems`

This interceptor also supports validating payload against specific custom constraints `expression`,
which uses a simple language familiar with devs is [CEL (Common Expression Language)](https://github.com/google/cel-spec)

This interceptor also supports validating payload against specific custom `metadata.rules` object in the schema
using CEL, too.

## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/Fr2xJvjAXUOZUKKmkW9KRx99K.svg)](https://asciinema.org/a/Fr2xJvjAXUOZUKKmkW9KRx99K)

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
 Network safeguard-validate-schema-payload-json_default  Creating
 Network safeguard-validate-schema-payload-json_default  Created
 Container kafka-client  Creating
 Container zookeeper  Creating
 Container zookeeper  Created
 Container kafka-client  Created
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka3  Creating
 Container kafka2  Created
 Container kafka1  Created
 Container kafka3  Created
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Creating
 Container gateway2  Created
 Container gateway1  Created
 Container schema-registry  Created
 Container kafka-client  Starting
 Container zookeeper  Starting
 Container zookeeper  Started
 Container kafka-client  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container kafka1  Started
 Container kafka3  Started
 Container kafka2  Started
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container gateway2  Starting
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container kafka2  Healthy
 Container gateway1  Starting
 Container schema-registry  Started
 Container gateway2  Started
 Container gateway1  Started
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container zookeeper  Healthy
 Container kafka2  Healthy
 Container kafka-client  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/6fP6i8sWLX3gBSPcWOMbSPCFD.svg)](https://asciinema.org/a/6fP6i8sWLX3gBSPcWOMbSPCFD)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ4Mjc1Mn0.MFmU34I8a3o6MTjFpJFFvaWvpBWxKmAqNXP69VU3tB0';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/uHYsNn08qs4NfHhGWX54Blrxa.svg)](https://asciinema.org/a/uHYsNn08qs4NfHhGWX54Blrxa)

</details>

## Creating topic topic-json-schema on teamA

Creating on `teamA`:

* Topic `topic-json-schema` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic topic-json-schema
```



</details>
<details>
<summary>Output</summary>

```
Created topic topic-json-schema.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/TgM9AmKN5Gy2f0zlhDSaYucgr.svg)](https://asciinema.org/a/TgM9AmKN5Gy2f0zlhDSaYucgr)

</details>

## Review the example json schema schema

Review the example json schema schema

```sh
cat user-schema-with-validation-rules.json
```

<details>
<summary>File content</summary>

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "minLength": 3,
      "maxLength": 50,
      "expression": "size(name) >= 3"
    },
    "age": {
      "type": "integer",
      "minimum": 0,
      "maximum": 120,
      "expression": "age >= 0 && age <= 120"
    },
    "email": {
      "type": "string",
      "format": "email",
      "expression": "email.contains('foo')"
    },
    "address": {
      "type": "object",
      "properties": {
        "street": {
          "type": "string",
          "minLength": 5,
          "maxLength": 15,
          "expression": "size(street) >= 5 && size(street) <= 15"
        },
        "city": {
          "type": "string",
          "minLength": 2,
          "maxLength": 50
        }
      },
      "expression": "size(address.street) > 1 && address.street.contains('paris') || address.city == 'paris'"
    },
    "hobbies": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 2,
      "expression": "size(hobbies) >= 2"
    }
  },
  "metadata": {
    "rules": [
      {
        "name": "check hobbies size",
        "expression": "size(message.hobbies) == 2",
        "message": "hobbies must have 2 items"
      },
      {
        "name": "checkAge",
        "expression": "message.age >= 18",
        "message": "age must be greater than or equal to 18"
      },
      {
        "name": "check email",
        "expression": "message.email.endsWith('example.com')",
        "message": "email should end with 'example.com'"
      },
      {
        "name": "check street",
        "expression": "size(message.address.street) >= 3",
        "message": "address.street length must be greater than equal to 3"
      }
    ]
  }
}
```

</details>

## Let's register it to the Schema Registry



<details open>
<summary>Command</summary>



```sh
curl -s \
  http://localhost:8081/subjects/topic-json-schema/versions \
  -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data "{\"schemaType\": \"JSON\", \"schema\": $(cat user-schema-with-validation-rules.json | jq tostring)}"
```



</details>
<details>
<summary>Output</summary>

```
{"id":1}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/33ATxct1Xu6apdaAl4hDCROwk.svg)](https://asciinema.org/a/33ATxct1Xu6apdaAl4hDCROwk)

</details>

## Review invalid payload

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

<details open>
<summary>Command</summary>



```sh
cat invalid-payload.json | jq -c | \
    kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-json-schema \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=1
```



</details>
<details>
<summary>Output</summary>

```
[2024-04-10 03:52:34,611] INFO KafkaJsonSchemaSerializerConfig values: 
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
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/l3F6ZlBoCK4DG8pDLGkxVrXdM.svg)](https://asciinema.org/a/l3F6ZlBoCK4DG8pDLGkxVrXdM)

</details>

## Let's send invalid data using the protocol

Unfortunately the message went through

<details>
<summary>Command</summary>



```sh
MAGIC_BYTE="\000"
SCHEMA_ID="\000\000\000\001"
JSON_PAYLOAD=$(cat invalid-payload.json | jq -c)
printf "${MAGIC_BYTE}${SCHEMA_ID}${JSON_PAYLOAD}" | \
  kcat \
    -b localhost:6969 \
    -X security.protocol=SASL_PLAINTEXT \
    -X sasl.mechanism=PLAIN \
    -X sasl.username=sa \
    -X sasl.password=$(cat teamA-sa.properties | awk -F"'" '/password=/{print $4}') \
    -P \
    -t topic-json-schema
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/IPxK5cNrVop31Oq97zINvs3P8.svg)](https://asciinema.org/a/IPxK5cNrVop31Oq97zINvs3P8)

</details>

## Let's consume it back

That's pretty bad, you are going to propagate wrong data within your system!

<details open>
<summary>Command</summary>



```sh
kafka-json-schema-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-json-schema \
    --from-beginning \
    --skip-message-on-error \
    --timeout-ms 3000
```



</details>
<details>
<summary>Output</summary>

```
[2024-04-10 03:52:36,140] INFO KafkaJsonSchemaDeserializerConfig values: 
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
[2024-04-10 03:52:36,838] ERROR Error processing message, skipping this message:  (kafka.tools.ConsoleConsumer$:44)
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
Caused by: org.apache.kafka.common.errors.SerializationException: JSON {"name":"D","age":17,"email":"bad email","address":{"street":"a way too lond adress that will not fit in your database","city":""},"hobbies":["reading"],"friends":[{"name":"Tom","age":17},{"name":"Emma","age":18}]} does not match schema {"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"name":{"type":"string","minLength":3,"maxLength":50,"expression":"size(name) >= 3"},"age":{"type":"integer","minimum":0,"maximum":120,"expression":"age >= 0 step-12-SH-OUTPUTstep-12-SH-OUTPUT age <= 120"},"email":{"type":"string","format":"email","expression":"email.contains('foo')"},"address":{"type":"object","properties":{"street":{"type":"string","minLength":5,"maxLength":15,"expression":"size(street) >= 5 step-12-SH-OUTPUTstep-12-SH-OUTPUT size(street) <= 15"},"city":{"type":"string","minLength":2,"maxLength":50}},"expression":"size(address.street) > 1 step-12-SH-OUTPUTstep-12-SH-OUTPUT address.street.contains('paris') || address.city == 'paris'"},"hobbies":{"type":"array","items":{"type":"string"},"minItems":2,"expression":"size(hobbies) >= 2"}},"metadata":{"rules":[{"name":"check hobbies size","expression":"size(message.hobbies) == 2","message":"hobbies must have 2 items"},{"name":"checkAge","expression":"message.age >= 18","message":"age must be greater than or equal to 18"},{"name":"check email","expression":"message.email.endsWith('example.com')","message":"email should end with 'example.com'"},{"name":"check street","expression":"size(message.address.street) >= 3","message":"address.street length must be greater than equal to 3"}]}}
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
[2024-04-10 03:52:36,838] ERROR Error processing message, skipping this message:  (kafka.tools.ConsoleConsumer$:44)
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
Caused by: org.apache.kafka.common.errors.SerializationException: JSON {"name":"D","age":17,"email":"bad email","address":{"street":"a way too lond adress that will not fit in your database","city":""},"hobbies":["reading"],"friends":[{"name":"Tom","age":17},{"name":"Emma","age":18}]} does not match schema {"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"name":{"type":"string","minLength":3,"maxLength":50,"expression":"size(name) >= 3"},"age":{"type":"integer","minimum":0,"maximum":120,"expression":"age >= 0 step-12-SH-OUTPUTstep-12-SH-OUTPUT age <= 120"},"email":{"type":"string","format":"email","expression":"email.contains('foo')"},"address":{"type":"object","properties":{"street":{"type":"string","minLength":5,"maxLength":15,"expression":"size(street) >= 5 step-12-SH-OUTPUTstep-12-SH-OUTPUT size(street) <= 15"},"city":{"type":"string","minLength":2,"maxLength":50}},"expression":"size(address.street) > 1 step-12-SH-OUTPUTstep-12-SH-OUTPUT address.street.contains('paris') || address.city == 'paris'"},"hobbies":{"type":"array","items":{"type":"string"},"minItems":2,"expression":"size(hobbies) >= 2"}},"metadata":{"rules":[{"name":"check hobbies size","expression":"size(message.hobbies) == 2","message":"hobbies must have 2 items"},{"name":"checkAge","expression":"message.age >= 18","message":"age must be greater than or equal to 18"},{"name":"check email","expression":"message.email.endsWith('example.com')","message":"email should end with 'example.com'"},{"name":"check street","expression":"size(message.address.street) >= 3","message":"address.street length must be greater than equal to 3"}]}}
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
[2024-04-10 03:52:39,846] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.TimeoutException
[2024-04-10 03:52:39,846] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/BBZ4CogSA2YXGp9mYIhGLl7rt.svg)](https://asciinema.org/a/BBZ4CogSA2YXGp9mYIhGLl7rt)

</details>

## Adding interceptor guard-schema-payload-validate

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

<details open>
<summary>Command</summary>



```sh
cat step-13-guard-schema-payload-validate.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-schema-payload-validate" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-13-guard-schema-payload-validate.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
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
{
  "message": "guard-schema-payload-validate is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/PiLl4DHIwuiZPd2NO2GeduTle.svg)](https://asciinema.org/a/PiLl4DHIwuiZPd2NO2GeduTle)

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
      "name": "guard-schema-payload-validate",
      "pluginClass": "io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin",
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
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/lSE5loSH2mdwIR2NEAvgjChTG.svg)](https://asciinema.org/a/lSE5loSH2mdwIR2NEAvgjChTG)

</details>

## Let's send invalid data using the protocol again

Perfect our interceptor did its magic and validated our rules

<details>
<summary>Command</summary>



```sh
MAGIC_BYTE="\000"
SCHEMA_ID="\000\000\000\001"
JSON_PAYLOAD=$(cat invalid-payload.json | jq -c)
printf "${MAGIC_BYTE}${SCHEMA_ID}${JSON_PAYLOAD}" | \
  kcat \
    -b localhost:6969 \
    -X security.protocol=SASL_PLAINTEXT \
    -X sasl.mechanism=PLAIN \
    -X sasl.username=sa \
    -X sasl.password=$(cat teamA-sa.properties | awk -F"'" '/password=/{print $4}') \
    -P \
    -t topic-json-schema
```



</details>
<details>
<summary>Output</summary>

```
% Delivery failed for message: Broker: Policy violation

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/hkWebD7BEVe5RM7gxmLFqfXWc.svg)](https://asciinema.org/a/hkWebD7BEVe5RM7gxmLFqfXWc)

</details>

## Check in the audit log that message was denied

Check in the audit log that message was denied in cluster `kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _conduktor_gateway_auditlogs \
    --from-beginning \
    --timeout-ms 3000 \| jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin")'
```


returns 1 event
```json
{
  "id" : "d425a57d-2b48-45df-9f28-5365fd8c0e42",
  "source" : "krn://cluster=7LQ3kqW2T9-c-6VmovJgow",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:28612"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T23:51:58.694086930Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin",
    "message" : "Request parameters do not satisfy the configured policy. Topic 'topic-json-schema' has invalid json schema payload: hobbies must have 2 items, age must be greater than or equal to 18, email should end with 'example.com', #/hobbies: expected minimum item count: 2, found: 1, #/name: expected minLength: 3, actual: 1, #/email: [bad email] is not a valid email address, #/address/city: expected minLength: 2, actual: 0, #/address/street: expected maxLength: 15, actual: 56, street does not match expression 'size(street) >= 5 && size(street) <= 15', address does not match expression 'size(address.street) > 1 && address.street.contains('paris') || address.city == 'paris'', hobbies does not match expression 'size(hobbies) >= 2', name does not match expression 'size(name) >= 3', email does not match expression 'email.contains('foo')'"
  }
}
```



</details>
<details>
<summary>Output</summary>

```
{"id":"6ccf55dd-3b94-40b7-9bd2-d6a5c039f97d","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"172.21.0.7:8888","remoteAddress":"192.168.65.1:40417"},"specVersion":"0.1.0","time":"2024-04-09T23:52:32.004586625Z","eventData":{"method":"POST","path":"/admin/vclusters/v1/vcluster/teamA/username/sa","body":"{\"lifeTimeSeconds\": 7776000}"}}
{"id":"50171456-93a7-410d-af1b-9738fd2aeee0","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.21.0.7:6969","remoteAddress":"/192.168.65.1:28995"},"specVersion":"0.1.0","time":"2024-04-09T23:52:32.873205834Z","eventData":"SUCCESS"}
{"id":"bc183eb1-3532-4488-acb2-8367c889cf55","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.21.0.7:6971","remoteAddress":"/192.168.65.1:56266"},"specVersion":"0.1.0","time":"2024-04-09T23:52:32.921435292Z","eventData":"SUCCESS"}
{"id":"2924a533-3c4f-4a68-8033-5815b57d2b98","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.21.0.7:6969","remoteAddress":"/192.168.65.1:28999"},"specVersion":"0.1.0","time":"2024-04-09T23:52:35.067017918Z","eventData":"SUCCESS"}
{"id":"653d646b-2179-4e00-8b31-1f04e5c42a9f","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.21.0.7:6969","remoteAddress":"/192.168.65.1:29000"},"specVersion":"0.1.0","time":"2024-04-09T23:52:35.619823210Z","eventData":"SUCCESS"}
{"id":"7e9f777e-1abf-4f3f-b3ab-480a43a59513","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.21.0.7:6969","remoteAddress":"/192.168.65.1:29001"},"specVersion":"0.1.0","time":"2024-04-09T23:52:36.505910586Z","eventData":"SUCCESS"}
{"id":"440b23b8-fa95-49f3-aada-7cba64235526","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.21.0.7:6969","remoteAddress":"/192.168.65.1:29002"},"specVersion":"0.1.0","time":"2024-04-09T23:52:36.535630461Z","eventData":"SUCCESS"}
{"id":"a41fe1c5-4e6b-4583-b9ec-b0a4f57b003c","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.21.0.7:6969","remoteAddress":"/192.168.65.1:29003"},"specVersion":"0.1.0","time":"2024-04-09T23:52:36.692598002Z","eventData":"SUCCESS"}
{"id":"0c5c0862-91c9-4c81-940e-055ff937c348","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"172.21.0.7:8888","remoteAddress":"192.168.65.1:40452"},"specVersion":"0.1.0","time":"2024-04-09T23:52:40.384161129Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/guard-schema-payload-validate","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"schemaRegistryConfig\" : {      \"host\" : \"http://schema-registry:8081\"    },    \"topic\" : \"topic-.*\",    \"schemaIdRequired\" : true,    \"validateSchema\" : true,    \"action\" : \"BLOCK\"  }}"}}
{"id":"870af38b-08cc-4338-967a-65aa28396f19","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"172.21.0.7:8888","remoteAddress":"192.168.65.1:40453"},"specVersion":"0.1.0","time":"2024-04-09T23:52:40.594064671Z","eventData":{"method":"GET","path":"/admin/interceptors/v1/vcluster/teamA","body":null}}
{"id":"d9507f14-9927-42bd-8bf5-7fcbb95af5ff","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.21.0.7:6969","remoteAddress":"/192.168.65.1:29031"},"specVersion":"0.1.0","time":"2024-04-09T23:52:40.648801046Z","eventData":"SUCCESS"}
{"id":"3bf82e7f-bbf6-47fe-ba56-117c499a7b97","source":"krn://cluster=mDZUqGpoRBeALgtL8gSIxg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:29031"},"specVersion":"0.1.0","time":"2024-04-09T23:52:40.953458421Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin","message":"Request parameters do not satisfy the configured policy. Topic 'topic-json-schema' has invalid json schema payload: hobbies must have 2 items, age must be greater than or equal to 18, email should end with 'example.com', #/hobbies: expected minimum item count: 2, found: 1, #/name: expected minLength: 3, actual: 1, #/email: [bad email] is not a valid email address, #/address/city: expected minLength: 2, actual: 0, #/address/street: expected maxLength: 15, actual: 56, street does not match expression 'size(street) >= 5 step-16-AUDITLOG-OUTPUTstep-16-AUDITLOG-OUTPUT size(street) <= 15', address does not match expression 'size(address.street) > 1 step-16-AUDITLOG-OUTPUTstep-16-AUDITLOG-OUTPUT address.street.contains('paris') || address.city == 'paris'', hobbies does not match expression 'size(hobbies) >= 2', name does not match expression 'size(name) >= 3', email does not match expression 'email.contains('foo')'"}}
[2024-04-10 03:52:45,201] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 12 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/G7y9EbXH9rfb5HvdjXa41ISYn.svg)](https://asciinema.org/a/G7y9EbXH9rfb5HvdjXa41ISYn)

</details>

## Let's now produce a valid payload



<details open>
<summary>Command</summary>



```sh
cat valid-payload.json | jq -c | \
    kafka-json-schema-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic topic-json-schema \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema.id=1
```



</details>
<details>
<summary>Output</summary>

```
[2024-04-10 03:52:46,242] INFO KafkaJsonSchemaSerializerConfig values: 
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
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/erFciRmwaUZIrmeaVmTRBlHtA.svg)](https://asciinema.org/a/erFciRmwaUZIrmeaVmTRBlHtA)

</details>

## And consume it back



<details open>
<summary>Command</summary>



```sh
kafka-json-schema-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic topic-json-schema \
    --from-beginning \
    --skip-message-on-error \
    --timeout-ms 3000
```



</details>
<details>
<summary>Output</summary>

```
[2024-04-10 03:52:47,806] INFO KafkaJsonSchemaDeserializerConfig values: 
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
[2024-04-10 03:52:48,428] ERROR Error processing message, skipping this message:  (kafka.tools.ConsoleConsumer$:44)
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
Caused by: org.apache.kafka.common.errors.SerializationException: JSON {"name":"D","age":17,"email":"bad email","address":{"street":"a way too lond adress that will not fit in your database","city":""},"hobbies":["reading"],"friends":[{"name":"Tom","age":17},{"name":"Emma","age":18}]} does not match schema {"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"name":{"type":"string","minLength":3,"maxLength":50,"expression":"size(name) >= 3"},"age":{"type":"integer","minimum":0,"maximum":120,"expression":"age >= 0 step-18-SH-OUTPUTstep-18-SH-OUTPUT age <= 120"},"email":{"type":"string","format":"email","expression":"email.contains('foo')"},"address":{"type":"object","properties":{"street":{"type":"string","minLength":5,"maxLength":15,"expression":"size(street) >= 5 step-18-SH-OUTPUTstep-18-SH-OUTPUT size(street) <= 15"},"city":{"type":"string","minLength":2,"maxLength":50}},"expression":"size(address.street) > 1 step-18-SH-OUTPUTstep-18-SH-OUTPUT address.street.contains('paris') || address.city == 'paris'"},"hobbies":{"type":"array","items":{"type":"string"},"minItems":2,"expression":"size(hobbies) >= 2"}},"metadata":{"rules":[{"name":"check hobbies size","expression":"size(message.hobbies) == 2","message":"hobbies must have 2 items"},{"name":"checkAge","expression":"message.age >= 18","message":"age must be greater than or equal to 18"},{"name":"check email","expression":"message.email.endsWith('example.com')","message":"email should end with 'example.com'"},{"name":"check street","expression":"size(message.address.street) >= 3","message":"address.street length must be greater than equal to 3"}]}}
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
[2024-04-10 03:52:48,428] ERROR Error processing message, skipping this message:  (kafka.tools.ConsoleConsumer$:44)
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
Caused by: org.apache.kafka.common.errors.SerializationException: JSON {"name":"D","age":17,"email":"bad email","address":{"street":"a way too lond adress that will not fit in your database","city":""},"hobbies":["reading"],"friends":[{"name":"Tom","age":17},{"name":"Emma","age":18}]} does not match schema {"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"name":{"type":"string","minLength":3,"maxLength":50,"expression":"size(name) >= 3"},"age":{"type":"integer","minimum":0,"maximum":120,"expression":"age >= 0 step-18-SH-OUTPUTstep-18-SH-OUTPUT age <= 120"},"email":{"type":"string","format":"email","expression":"email.contains('foo')"},"address":{"type":"object","properties":{"street":{"type":"string","minLength":5,"maxLength":15,"expression":"size(street) >= 5 step-18-SH-OUTPUTstep-18-SH-OUTPUT size(street) <= 15"},"city":{"type":"string","minLength":2,"maxLength":50}},"expression":"size(address.street) > 1 step-18-SH-OUTPUTstep-18-SH-OUTPUT address.street.contains('paris') || address.city == 'paris'"},"hobbies":{"type":"array","items":{"type":"string"},"minItems":2,"expression":"size(hobbies) >= 2"}},"metadata":{"rules":[{"name":"check hobbies size","expression":"size(message.hobbies) == 2","message":"hobbies must have 2 items"},{"name":"checkAge","expression":"message.age >= 18","message":"age must be greater than or equal to 18"},{"name":"check email","expression":"message.email.endsWith('example.com')","message":"email should end with 'example.com'"},{"name":"check street","expression":"size(message.address.street) >= 3","message":"address.street length must be greater than equal to 3"}]}}
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
{"name":"Doe","age":18,"email":"foo.doe@example.com","address":{"street":"123 Main paris","city":"Anytown paris"},"hobbies":["reading","cycling"],"friends":[{"name":"Tom","age":9},{"name":"Emma","age":10}]}
[2024-04-10 03:52:51,432] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.TimeoutException
[2024-04-10 03:52:51,432] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 2 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/Cl6T3re8CPYtc147GuznYe3Fz.svg)](https://asciinema.org/a/Cl6T3re8CPYtc147GuznYe3Fz)

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
 Container gateway1  Stopping
 Container kafka-client  Stopping
 Container gateway2  Stopping
 Container schema-registry  Stopping
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
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka1  Removed
 Container kafka2  Removed
 Container kafka-client  Stopped
 Container kafka-client  Removing
 Container kafka-client  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network safeguard-validate-schema-payload-json_default  Removing
 Network safeguard-validate-schema-payload-json_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/aYrJyZtUXCZIRu3k80EQvZ8ea.svg)](https://asciinema.org/a/aYrJyZtUXCZIRu3k80EQvZ8ea)

</details>

# Conclusion

You can enrich your existing schema to add even more data quality to your systems!

