# Schema Id validation



## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/bQZ6qPyEO47NsdHs6t3TYaaSm.svg)](https://asciinema.org/a/bQZ6qPyEO47NsdHs6t3TYaaSm)

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
 Network safeguard-schema-id_default  Creating
 Network safeguard-schema-id_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container kafka-client  Created
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka2  Created
 Container kafka3  Created
 Container kafka1  Created
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Creating
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
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container gateway2  Starting
 Container kafka1  Healthy
 Container schema-registry  Starting
 Container kafka1  Healthy
 Container gateway1  Starting
 Container schema-registry  Started
 Container gateway1  Started
 Container gateway2  Started
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container zookeeper  Healthy
 Container kafka-client  Healthy
 Container schema-registry  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/m9FMVyZ64aJ8PVp0kCeogn1gE.svg)](https://asciinema.org/a/m9FMVyZ64aJ8PVp0kCeogn1gE)

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
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ4MDYxNX0.b8GXqe_BdbGajYcgY711xuFK9qJKzGIZz6ZOxyDCL-4';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/NYLAvvIGNG82WT8btTyaWmKVL.svg)](https://asciinema.org/a/NYLAvvIGNG82WT8btTyaWmKVL)

</details>

## Creating topic users on teamA

Creating on `teamA`:

* Topic `users` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic users
```



</details>
<details>
<summary>Output</summary>

```
Created topic users.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/T6JmFW13fJRiHwJfA3r90WARs.svg)](https://asciinema.org/a/T6JmFW13fJRiHwJfA3r90WARs)

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
users

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/mB0ESjh6VW2OtNhRwwgj6Bv3p.svg)](https://asciinema.org/a/mB0ESjh6VW2OtNhRwwgj6Bv3p)

</details>

## Adding interceptor schema-id



Creating the interceptor named `schema-id` of the plugin `io.conduktor.gateway.interceptor.safeguard.TopicRequiredSchemaIdPolicyPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.TopicRequiredSchemaIdPolicyPlugin",
  "priority" : 100,
  "config" : {
    "topic" : "users",
    "schemaIdRequired" : true
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-08-schema-id.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/schema-id" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-schema-id.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.TopicRequiredSchemaIdPolicyPlugin",
  "priority": 100,
  "config": {
    "topic": "users",
    "schemaIdRequired": true
  }
}
{
  "message": "schema-id is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/qbHOLbk0vfCCWrtOuUI6qLpUn.svg)](https://asciinema.org/a/qbHOLbk0vfCCWrtOuUI6qLpUn)

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
      "name": "schema-id",
      "pluginClass": "io.conduktor.gateway.interceptor.safeguard.TopicRequiredSchemaIdPolicyPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "topic": "users",
        "schemaIdRequired": true
      }
    }
  ]
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/jul0EYxcI221Nw6f9CbEo95OU.svg)](https://asciinema.org/a/jul0EYxcI221Nw6f9CbEo95OU)

</details>

## Producing 1 message in users

Producing 1 message in `users` in cluster `teamA`

<details open>
<summary>Command</summary>



Sending 1 event
```json
{
  "msg" : "hello world"
}
```
with


```sh
echo '{"msg":"hello world"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> org.apache.kafka.common.errors.PolicyViolationException:
>> Request parameters do not satisfy the configured policy.
>>Topic 'users' with schemaId is required.
> ```





</details>
<details>
<summary>Output</summary>

```
[2024-04-10 03:16:59,779] ERROR Error when sending message to topic users with key: null, value: 21 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Topic 'users' with schemaId is required.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/sJ5w8IYOPeWId52pFTYNjDNVi.svg)](https://asciinema.org/a/sJ5w8IYOPeWId52pFTYNjDNVi)

</details>

## Consuming from users

Consuming from users in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --timeout-ms 10000 | jq
```



</details>
<details>
<summary>Output</summary>

```json
[2024-04-10 03:17:11,021] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 0 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/GZavkrkF3FnnOlXvt34Q2I6p1.svg)](https://asciinema.org/a/GZavkrkF3FnnOlXvt34Q2I6p1)

</details>

## Send avro message



<details>
<summary>Command</summary>



```sh
echo '{
    "name": "conduktor",
    "username": "test@conduktor.io",
    "password": "password1",
    "visa": "visa123456",
    "address": "Conduktor Towers, London"
}' | \
  jq -c | \
      kafka-json-schema-console-producer  \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic users \
        --property schema.registry.url=http://localhost:8081 \
        --property value.schema='{
            "title": "User",
            "type": "object",
            "properties": {
                "name": { "type": "string" },
                "username": { "type": "string" },
                "password": { "type": "string" },
                "visa": { "type": "string" },
                "address": { "type": "string" }
            }
        }'
```



</details>
<details>
<summary>Output</summary>

```
[2024-04-10 03:17:12,375] INFO KafkaJsonSchemaSerializerConfig values: 
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

[![asciicast](https://asciinema.org/a/21ohB4q49hQASuAXjSUt3eGQT.svg)](https://asciinema.org/a/21ohB4q49hQASuAXjSUt3eGQT)

</details>

## Get subjects



<details open>
<summary>Command</summary>



```sh
curl --silent http://localhost:8081/subjects/ | jq     
```



</details>
<details>
<summary>Output</summary>

```
[
  "users-value"
]

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/bHK8sRw1ZVSWpZHz20AxyZbOr.svg)](https://asciinema.org/a/bHK8sRw1ZVSWpZHz20AxyZbOr)

</details>

## Consuming from users

Consuming from users in cluster `teamA`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --timeout-ms 10000 | jq
```



</details>
<details>
<summary>Output</summary>

```json
jq: parse error: Invalid numeric literal at line 1, column 6
[2024-04-10 03:17:24,912] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/0ayxNF7xTPFUFJlpe81fRt6Ma.svg)](https://asciinema.org/a/0ayxNF7xTPFUFJlpe81fRt6Ma)

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
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
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
 Network safeguard-schema-id_default  Removing
 Network safeguard-schema-id_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/NkUynkyL0GtqXQcJJeinBlJZk.svg)](https://asciinema.org/a/NkUynkyL0GtqXQcJJeinBlJZk)

</details>

# Conclusion

You can now make sure you don't fall because of a wrong message

