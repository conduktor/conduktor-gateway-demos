# Conduktor Gateway Schema Validation Demo

## What is Conduktor Gateway Schema Validation?

Conduktor Gateway's Schema Validation detects messages that have invalid schema information and rejects them. 

### Architecture diagram
![architecture diagram](images/schema-validation.png "schema validation")

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* 2 Schema Registry containers
* A single Conduktor Gateway container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

Note that there are 2 Schema registries. 

This means that schemas created by Kafka clients will not be valid in Gateway, enabling the test scenario.

### Step 2: Start the environment

Start the environment with

```bash
docker compose up --wait --detach
```

### Step 3: Create topics

Let's create a topic using the Kafka console tools, the below creates a topic named `sr-topic`.

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic sr-topic
```

List the created topic

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --list
```

### Step 4: Configure Schema validation

Conduktor Gateway provides a REST API that can be used to configure the schema validation interceptor. 

The command below will create an interceptor for validating that the records on topic `sr-topic` refer to a schema that exists in the schema registry referred to by the Gateway. 

```bash
docker compose exec kafka-client \
  curl \
    --user admin:conduktor \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/sr-required" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.safeguard.TopicRequiredSchemaIdPolicyPlugin",
        "priority": 100,
        "config": {
            "topic": "sr-topic",
            "schemaIdRequired": true
        }
    }'
```

Verify 

```bash
docker compose exec kafka-client \
    curl \
        --silent \
        --user admin:conduktor \
        --request GET "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/sr-required" \
        --header 'Content-Type: application/json' | jq
```

### Step 5: Produce bad data to the topic

Let's produce a simple record to the topic.

```bash
echo '{"msg": "hello world"}' | 
  docker compose exec -T kafka-client \
      kafka-console-producer  \
          --bootstrap-server conduktor-gateway:6969 \
          --producer.config /clientConfig/gateway.properties \
          --topic sr-topic
```

The result is 

```
[2023-08-25 14:46:03,620] ERROR Error when sending message to topic sr-topic with key: null, value: 22 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Topic 'sr-topic' with schemaId is required.
```

### Step 6: Produce good data to the topic

```bash
echo '{ 
    "name": "conduktor",
    "username": "test@conduktor.io",
    "password": "password1",
    "visa": "visa123456",
    "address": "Conduktor Towers, London" 
}' | jq -c | docker compose exec -T schema-registry \
    kafka-json-schema-console-producer  \
        --bootstrap-server conduktor-gateway:6969 \
        --producer.config /clientConfig/gateway.properties \
        --topic sr-topic \
        --property schema.registry.url=http://schema-registry:8081 \
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

### Step 6: Confirm the schemas

To see why this happens let's query the 2 schema registries for the subject we are trying to produce with.

First if we look at the client Schema Registry (i.e. the one used by the producer) we see a schema present.

```bash
docker compose exec kafka-client \
  curl --silent http://schema-registry:8081/subjects/sr-topic-value/versions/1 | jq
```

produces:

```bash
{
  "subject": "sr-topic-value",
  "version": 1,
  "id": 1,
  "schemaType": "JSON",
  "schema": "{\"title\":\"User\",\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"},\"username\":{\"type\":\"string\"},\"password\":{\"type\":\"string\"},\"visa\":{\"type\":\"string\"},\"address\":{\"type\":\"string\"}}}"
}
```

If we run the same queries against the Schema Registry associated with Conduktor Gateway we do not see the schema

```bash
docker compose exec kafka-client \
  curl http://schema-registry:8081/subjects/sr-topic-value/versions/1 | jq
```

produces:

```bash
{
  "error_code": 40401,
  "message": "Subject 'sr-topic-value' not found."
}
```

Because the subject is not available in this Schema Registry it is rejected by the Gateway.

### Step 7: Differing schemas

Now let's add a schema with the correct Id but incorrect content to the Gateway cluster

```bash
docker compose exec kafka-client \
  curl \
    --request PUT http://schema-registry:8081/config \
    --header "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data-raw '{"compatibility": "NONE"}'
```

```bash
docker compose exec kafka-client curl \
  --request POST http://schema-registry:8081/subjects/sr-topic-value/versions \
  --header "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data-raw '{
	"schemaType": "JSON",
	"schema": "{\"type\":\"object\",\"properties\": {\"name\":{\"type\":\"integer\"}},\"additionalProperties\": false}"
  }'
```

We have now created the situation where client and Gateway see different schemas for id 1

```bash
docker compose exec kafka-client \
  curl \
    --header "Content-Type: application/vnd.schemaregistry.v1+json" \
    http://schema-registry:8081/schemas/ids/1 | jq
```

produces:

```bash
{
  "schemaType": "JSON",
  "schema": "{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"}}}"
}
```

and

```bash
docker compose exec kafka-client \
  curl \
    --header "Content-Type: application/vnd.schemaregistry.v1+json" \
    http://schema-registry:8081/schemas/ids/1 | jq
```

produces:

```bash
{
  "schemaType": "JSON",
  "schema": "{\"title\":\"User\",\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"},\"username\":{\"type\":\"string\"},\"password\":{\"type\":\"string\"},\"visa\":{\"type\":\"string\"},\"address\":{\"type\":\"string\"}}}"
}
```

### Step 8: Produce data to the topic again

We produce with the client schema, this time schema id: 1 is present on both Schema Registries but the Gateway should not be able to deserialize the message using it's schema.

```bash
echo '{ 
    "name": "conduktor",
    "username": "test@conduktor.io",
    "password": "password1",
    "visa": "visa123456",
    "address": "Conduktor Towers, London" 
}' | jq -c | docker compose exec -T schema-registry \
    kafka-json-schema-console-producer  \
        --bootstrap-server conduktor-gateway:6969 \
        --producer.config /clientConfig/gateway.properties \
        --topic sr-topic \
        --property schema.registry.url=http://schema-registry:8081 \
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

You should once again see an error like this:

```bash
[2022-12-12 21:51:59,888] ERROR Error when sending message to topic sr-topic with key: null, value: 136 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. SchemaId is required, offset=0
```
