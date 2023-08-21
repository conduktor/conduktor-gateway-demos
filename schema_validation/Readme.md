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

Note that there are 2 Schema registries. Client-schema-registry will be used to produce new messages through kafka clients. Schema-registry is attached to Conduktor Gateway.

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
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/tenants/someTenant/interceptors/sr-required" \
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

### Step 5: Produce data to the topic

Let's produce a simple record to the topic.

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
        --property schema.registry.url=http://client-schema-registry:8082 \
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

You should see something similar to the following produced:

```bash
[2022-12-12 21:49:51,205] ERROR Error when sending message to topic sr-topic with key: null, value: 136 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. SchemaId is required, offset=0
```

### Step 6: Confirm the schemas

To see why this happens let's query the 2 schema registries for the subject we are trying to produce with.

First if we look at the client Schema Registry (i.e. the one used by the producer) we see a schema present.

```bash
docker compose exec kafka-client curl http://client-schema-registry:8082/subjects/sr-topic-value/versions/1 | jq
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
docker compose exec kafka-client curl http://schema-registry:8081/subjects/sr-topic-value/versions/1 | jq
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
docker compose exec kafka-client curl -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"compatibility": "NONE"}' \
  http://schema-registry:8081/config
```

```bash
docker compose exec kafka-client curl \
  -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{
	"schemaType": "JSON",
	"schema": "{\"type\":\"object\",\"properties\": {\"name\":{\"type\":\"integer\"}},\"additionalProperties\": false}"
  }' \
  http://schema-registry:8081/subjects/sr-topic-value/versions     
```

We have now created the situation where client and Gateway see different schemas for id 1

```bash
docker compose exec kafka-client curl -H "Content-Type: application/vnd.schemaregistry.v1+json" \
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
docker compose exec kafka-client curl -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  http://client-schema-registry:8082/schemas/ids/1 | jq
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
        --property schema.registry.url=http://client-schema-registry:8082 \
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
