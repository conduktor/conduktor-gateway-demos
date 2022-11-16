# Conduktor Proxy Chaos Demo

## What is Conduktor Proxy Chaos?

Chaos testing is the process of testing a distributed computing system to ensure that it can withstand unexpected disruptions. Kafka is an extremely resilient system and so it can be difficult to injects disruptions in order to be sure that applications can handle them.

Conduktor Proxy comes to the rescue, simulating common Kafka disruptions without and actual disruption occurring in the underlying Kafka cluster. 

In this demo we will inject the following disruptions with Conduktor Proxy and observe the result:

* Broken Broker - Inject intermittent errors in client connections to brokers
* Duplication - Simulate request duplication
* Leader Election - Simulate leader elections on the underlying Kafka cluster
* Random Bytes - Add random bytes to message data
* Slow Broker - Introduce intermittent latency in broker communication
* Slow Topic - Introduce latency for specific topics
* Invalid Schema Id - Siumulate broker responses as if the schema provided in a message was invalid.

## Running the demo

### Step 1: review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Proxy container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: start the environment

Start the environment with

```bash
docker-compose up -d
```

### Step 3: Create topics

We create topics using the Kafka console tools, the below creates a topic named `conduktor_topic`

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic conduktor_topic
```

List the created topic

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --list
```

### Step 4: Broken Broker

Conduktor Proxy exposes a REST API to configure the chaos features.

The command below will instruct Conduktor Proxy to inject failures for some Produce requests. 

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/broken-broker" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": {
	        "brokerIds": [],
	        "duration": 6000,
	        "durationUnit": "MILLISECONDS",
	        "quietPeriod": 20000,
	        "quietPeriodUnit": "MILLISECONDS",
	        "minLatencyToAddInMilliseconds": 6000,
	        "maxLatencyToAddInMilliseconds": 7000,
	        "errors": ["REQUEST_TIMED_OUT", "BROKER_NOT_AVAILABLE", "OFFSET_OUT_OF_RANGE", "NOT_ENOUGH_REPLICAS", "INVALID_REQUIRED_ACKS"]
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```
### Step 6 Configure Decryption

Next we configure Conduktor Proxy to decrypt the fields when fetching data

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/feature/decryption" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
            "topic": "encrypted_topic",
            "fields": [ { 
                "fieldName": "password",
                "keySecretId": "secret-key-password",
                "algorithm": { 
                    "type": "TINK/AES_GCM",
                    "kms": "TINK/KMS_INMEM" 
                }
            },
            { 
                "fieldName": "visa",
                "keySecretId": "secret-key-visaNumber",
                "algorithm": { 
                    "type": "TINK/AES_GCM",
                    "kms": "TINK/KMS_INMEM" 
                } 
            }] 
        },
        "direction": "RESPONSE",
        "apiKeys": "FETCH"
    }'
```


### Step 6: Produce data to the topic

Let's produce a simple record to the encrypted topic.

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
        --topic encrypted_topic \
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

### Step 7: Consume from the topic

Let's consume from our `encrypted_topic`.

```bash
docker-compose exec schema-registry \
  kafka-json-schema-console-consumer \
    --bootstrap-server conduktor-proxy:6969 \
    --consumer.config /clientConfig/proxy.properties \
    --topic encrypted_topic \
    --from-beginning \
    --max-messages 1 | jq .
```

You should see the encrypted fields have been decrypted on read as below:

```json
{
  "name": "conduktor",
  "username": "test@conduktor.io",
  "password": "password1",
  "visa": "visa123456",
  "address": "Conduktor Towers, London"
}
```

### Step 8: Confirm encryption at rest

To confirm the fields are encrypted in Kafka we can consume directly from the underlying Kafka cluster.

```bash
docker-compose exec schema-registry \
  kafka-json-schema-console-consumer \
    --bootstrap-server kafka1:9092 \
    --topic 1-1encrypted_topic \
    --from-beginning \
    --max-messages 1 | jq .
```

You should see an output similar to the below:

```json
{
  "name": "conduktor",
  "username": "test@conduktor.io",
  "password": "AUXGXFa8bcMPws2DXsnBTVxzwpWyQusuUsEPWtKItFnGoQoQLd4zSfZjqofomWHdqA==",
  "visa": "ARA3jO6WyWNuhg2wwag0ouLbAGE7fjs+lCAJeXx9J6BZzM/FEiJt5afv4dPf1qNDWS8=",
  "address": "Conduktor Towers, London"
}
```