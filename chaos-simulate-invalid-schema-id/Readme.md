# Chaos Simulate Invalid Schema Id

This interceptor injects Schema Ids into messages, simulating a situation where clients cannot deserialize messages with the schema information provided.

This demo will run you through some of these use cases step-by-step.

## View the full demo in realtime

You can either follow all the steps manually, or just enjoy the recording

[![asciicast](https://asciinema.org/a/ESLdQoIxUK9PQGsA3JjCHo4G8.svg)](https://asciinema.org/a/ESLdQoIxUK9PQGsA3JjCHo4G8)

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
gateway1          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway1          34 seconds ago   Up 16 seconds (healthy)   0.0.0.0:6969-6971->6969-6971/tcp, 0.0.0.0:8888->8888/tcp
gateway2          conduktor/conduktor-gateway:2.5.0        "java -cp @/app/jib-…"   gateway2          34 seconds ago   Up 16 seconds (healthy)   0.0.0.0:7969-7971->7969-7971/tcp, 0.0.0.0:8889->8888/tcp
kafka1            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka1            34 seconds ago   Up 26 seconds (healthy)   9092/tcp, 0.0.0.0:19092->19092/tcp
kafka2            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka2            34 seconds ago   Up 26 seconds (healthy)   9092/tcp, 0.0.0.0:19093->19093/tcp
kafka3            confluentinc/cp-kafka:latest             "/etc/confluent/dock…"   kafka3            34 seconds ago   Up 27 seconds (healthy)   9092/tcp, 0.0.0.0:19094->19094/tcp
schema-registry   confluentinc/cp-schema-registry:latest   "/etc/confluent/dock…"   schema-registry   34 seconds ago   Up 16 seconds (healthy)   0.0.0.0:8081->8081/tcp
zookeeper         confluentinc/cp-zookeeper:latest         "/etc/confluent/dock…"   zookeeper         34 seconds ago   Up 32 seconds (healthy)   2181/tcp, 2888/tcp, 3888/tcp

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
 Network chaos-simulate-invalid-schema-id_default  Creating
 Network chaos-simulate-invalid-schema-id_default  Created
 Container zookeeper  Creating
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka1  Creating
 Container kafka2  Creating
 Container kafka2  Created
 Container kafka3  Created
 Container kafka1  Created
 Container schema-registry  Creating
 Container gateway1  Creating
 Container gateway2  Creating
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
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container kafka2  Started
 Container kafka3  Started
 Container kafka1  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container gateway2  Starting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container gateway1  Starting
 Container kafka3  Healthy
 Container schema-registry  Starting
 Container schema-registry  Started
 Container gateway1  Started
 Container gateway2  Started
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container zookeeper  Healthy
 Container schema-registry  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzcxODgyMX0.yaUvfzzhIoyiYLOMBn3-7rqkqu_V4qMtVORlQ2IcLK8';
bootstrap.servers=localhost:6969
```

</details>


## Creating topic `with-schema` on `teamA`

Creating topic `with-schema` on `teamA`
* Topic `with-schema` with partitions:1 and replication-factor:1

```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic with-schema
```

<details>
  <summary>Realtime command output</summary>

  ![Creating topic `with-schema` on `teamA`](images/step-07-CREATE_TOPICS.gif)

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
    --topic with-schema
Created topic with-schema.

```

</details>
      


## Adding interceptor `simulate-invalid-schema-id`

Let's create the interceptor against the virtual cluster `teamA`, instructing Conduktor Gateway to inject Schema Ids into messages, simulating a situation where clients cannot deserialize messages with the schema information provided.


Creating the interceptor named `simulate-invalid-schema-id` of the plugin `io.conduktor.gateway.interceptor.chaos.SimulateInvalidSchemaIdPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.chaos.SimulateInvalidSchemaIdPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "with-schema",
    "invalidSchemaId" : 999,
    "target" : "CONSUME"
  }
}
```

Here's how to send it:

```sh
cat step-08-simulate-invalid-schema-id.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/simulate-invalid-schema-id" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-simulate-invalid-schema-id.json | jq
```

<details>
  <summary>Realtime command output</summary>

  ![Adding interceptor `simulate-invalid-schema-id`](images/step-08-ADD_INTERCEPTOR.gif)

</details>


<details>
<summary>Command output</summary>

```sh

cat step-08-simulate-invalid-schema-id.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateInvalidSchemaIdPlugin",
  "priority": 100,
  "config": {
    "topic": "with-schema",
    "invalidSchemaId": 999,
    "target": "CONSUME"
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/simulate-invalid-schema-id" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-simulate-invalid-schema-id.json | jq
{
  "message": "simulate-invalid-schema-id is created"
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
      "name": "simulate-invalid-schema-id",
      "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateInvalidSchemaIdPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "topic": "with-schema",
        "invalidSchemaId": 999,
        "target": "CONSUME"
      }
    }
  ]
}

```

</details>
      


## Let's produce some records to our created topic



```sh
echo '{"message": "hello world"}' | \
  kafka-json-schema-console-producer \
  --bootstrap-server localhost:6969 \
  --topic with-schema \
  --producer.config teamA-sa.properties \
  --property value.schema='{
  "title": "someSchema",
  "type": "object",
  "properties": {
    "message": {
      "type": "string"
    }
  }
}'
```

<details>
  <summary>Realtime command output</summary>

  ![Let's produce some records to our created topic](images/step-10-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

echo '{"message": "hello world"}' | \
  kafka-json-schema-console-producer \
  --bootstrap-server localhost:6969 \
  --topic with-schema \
  --producer.config teamA-sa.properties \
  --property value.schema='{
  "title": "someSchema",
  "type": "object",
  "properties": {
    "message": {
      "type": "string"
    }
  }
}'
[2024-01-22 18:01:05,370] INFO KafkaJsonSchemaSerializerConfig values: 
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
      


## Let's consume them with a schema aware consumer.



```sh
kafka-json-schema-console-consumer \
--bootstrap-server localhost:6969 \
--topic with-schema \
--consumer.config teamA-sa.properties \
--from-beginning
```

<details>
  <summary>Realtime command output</summary>

  ![Let's consume them with a schema aware consumer.](images/step-11-SH.gif)

</details>


<details>
<summary>Command output</summary>

```sh

kafka-json-schema-console-consumer \
--bootstrap-server localhost:6969 \
--topic with-schema \
--consumer.config teamA-sa.properties \
--from-beginning
[2024-01-22 18:01:07,227] INFO KafkaJsonSchemaDeserializerConfig values: 
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
Processed a total of 1 messages
[2024-01-22 18:01:07,943] ERROR Unknown error when running consumer:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.SerializationException: Error retrieving JSON schema for id 999
	at io.confluent.kafka.serializers.AbstractKafkaSchemaSerDe.toKafkaException(AbstractKafkaSchemaSerDe.java:776)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:238)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:135)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:101)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter.writeTo(JsonSchemaMessageFormatter.java:92)
	at io.confluent.kafka.formatter.SchemaMessageFormatter.writeTo(SchemaMessageFormatter.java:266)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:116)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:76)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:53)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Caused by: io.confluent.kafka.schemaregistry.client.rest.exceptions.RestClientException: Schema 999 not found; error code: 40403
	at io.confluent.kafka.schemaregistry.client.rest.RestService.sendHttpRequest(RestService.java:333)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.httpRequest(RestService.java:406)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.getId(RestService.java:882)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.getId(RestService.java:855)
	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.getSchemaByIdFromRegistry(CachedSchemaRegistryClient.java:332)
	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.getSchemaBySubjectAndId(CachedSchemaRegistryClient.java:463)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:133)
	... 8 more
[2024-01-22 18:01:07,943] ERROR Unknown error when running consumer:  (kafka.tools.ConsoleConsumer$:44)
org.apache.kafka.common.errors.SerializationException: Error retrieving JSON schema for id 999
	at io.confluent.kafka.serializers.AbstractKafkaSchemaSerDe.toKafkaException(AbstractKafkaSchemaSerDe.java:776)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:238)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:135)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:101)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter.writeTo(JsonSchemaMessageFormatter.java:92)
	at io.confluent.kafka.formatter.SchemaMessageFormatter.writeTo(SchemaMessageFormatter.java:266)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:116)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:76)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:53)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Caused by: io.confluent.kafka.schemaregistry.client.rest.exceptions.RestClientException: Schema 999 not found; error code: 40403
	at io.confluent.kafka.schemaregistry.client.rest.RestService.sendHttpRequest(RestService.java:333)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.httpRequest(RestService.java:406)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.getId(RestService.java:882)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.getId(RestService.java:855)
	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.getSchemaByIdFromRegistry(CachedSchemaRegistryClient.java:332)
	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.getSchemaBySubjectAndId(CachedSchemaRegistryClient.java:463)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:133)
	... 8 more

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

  ![Tearing down the docker environment](images/step-12-DOCKER.gif)

</details>


<details>
<summary>Command output</summary>

```sh

docker compose down --volumes
 Container schema-registry  Stopping
 Container gateway1  Stopping
 Container gateway2  Stopping
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway2  Removed
 Container gateway1  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka1  Stopping
 Container kafka3  Stopping
 Container kafka2  Stopping
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network chaos-simulate-invalid-schema-id_default  Removing
 Network chaos-simulate-invalid-schema-id_default  Removed

```

</details>
      


# Conclusion

Yes, Chaos Simulate Invalid Schema Id is simple as it!

