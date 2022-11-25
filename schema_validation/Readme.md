# Conduktor Proxy Schema Validation Demo

## What is Conduktor Proxy Schema Validation?

Conduktor Proxy's Schema Validation feature detects messages that have invalid schema information and rejects them. 

## Running the demo

### Step 1: review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* 2 Schema Registry containers
* A single Conduktor Proxy container
* A Conduktor Platform container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

Note that there are 2 Schema registries. client-schema-registry will be used to produce new messages through kafka clients. schema-registry is attached to Conduktor Proxy.

This means that schemas created by Kafka clients will not be valid in proxy, enabling the test scenario.

### Step 2: review the platform configuration

`platform-config.yaml` defines 2 clusters:

* Backing Kafka - this is a direct connection to the underlying Kafka cluster hosting the demo
* Proxy - a connection through Conduktor Proxy to the underlying Kafka

Note: Proxy and backing Kafka can use different security schemes. 
In this case the backing Kafka is PLAINTEXT but the proxy is SASL_PLAIN.

### Step 3: start the environment

Start the environment with

```bash
docker-compose up -d
```

### Step 4: Create topics

We create topics using the Kafka console tools, the below creates a topic named `sr_topic`

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic sr_topic
```

List the created topic

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --list
```

### Step 5: Configure Schema validation

Conduktor Proxy provides a REST API that can be used to configure the schema validation feature. 

The command below will instruct Conduktor Proxy to validate that the records on topic `sr_topic` refer to a schema that exists in the schema registry referred to by the proxy. 

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/feature/schema-validation" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
            "topic": "sr_topic",
            "checkDeserialization": false
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```

### Step 6: Produce data to the topic

Let's produce a simple record to the topic.

```bash
echo '{ 
    "name": "conduktor",
    "username": "test@conduktor.io",
    "password": "password1",
    "visa": "visa123456",
    "address": "Conduktor Towers, London" 
}' | jq -c | docker-compose exec -T schema-registry \
    kafka-json-schema-console-producer  \
        --bootstrap-server conduktor-proxy:6969 \
        --producer.config /clientConfig/proxy.properties \
        --topic sr_topic \
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
[2022-11-25 21:57:31,863] ERROR Error when sending message to topic sr_topic with key: null, value: 136 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.InvalidRecordException: This record has failed the validation on broker and hence will be rejected.
```

### Step 7: Confirm the schemas

To see why this happens let's query the 2 schema registries for the subject we are trying to produce with.

First if we look at the client Schema Registry (i.e. the one used by the producer) we see a schema present.

```bash
docker-compose exec kafka-client curl http://client-schema-registry:8082/subjects/sr_topic-value/versions/1 | jq
```

produces:

```bash
{
  "subject": "sr_topic-value",
  "version": 1,
  "id": 1,
  "schemaType": "JSON",
  "schema": "{\"title\":\"User\",\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"},\"username\":{\"type\":\"string\"},\"password\":{\"type\":\"string\"},\"visa\":{\"type\":\"string\"},\"address\":{\"type\":\"string\"}}}"
}
```

If we run the same queries against the Schema Registry associated with Conduktor Proxy we do not see the schema

```bash
docker-compose exec kafka-client curl http://schema-registry:8081/subjects/sr_topic-value/versions/1 | jq
```

produces:

```bash
{
  "error_code": 40401,
  "message": "Subject 'sr_topic-value' not found."
}
```

Because the subject is not available in this Schema Registry it is rejected by the proxy.
