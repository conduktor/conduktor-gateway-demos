# Limit connection Safeguard Demo

In this demo we will impose limit connection attempts because creating a new connection is expensive

### Video

[![asciicast](https://asciinema.org/a/mzZ1z9EjoLhilyGZwsx3GLCbC.svg)](https://asciinema.org/a/mzZ1z9EjoLhilyGZwsx3GLCbC)

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Proxy container
* A Conduktor Platform container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Review the platform configuration

`platform-config.yaml` defines 2 clusters:

* Backing Kafka - this is a direct connection to the underlying Kafka cluster hosting the demo
* Proxy - a connection through Conduktor Proxy to the underlying Kafka

Note: Proxy and backing Kafka can use different security schemes. 
In this case the backing Kafka is PLAINTEXT but the proxy is SASL_PLAIN.

### Step 3: Start the environment

Start the environment with

```bash
docker-compose up -d zookeeper kafka1 kafka2 conduktor-proxy kafka-client
```

### Step 4: Create topics

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

### Step 5: Configure safeguard

Conduktor Proxy provides a REST API used to configure the safeguard feature to limit 1 connection only in 20 seconds

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/feature/guard-limit-connection" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
            "connectionsLimit": 1,
            "duration": 20,
            "durationUnit": "SECONDS"
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```

### Step 6: Attempt to create new connection

Let's produce to the `conduktor_topic` topic 

```bash
echo 'testMessage' | docker-compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server conduktor-proxy:6969 \
        --producer.config /clientConfig/proxy.properties \
        --topic conduktor_topic
```

You should see an output similar to the following in the second terminal:

```bash
ERROR ERROR Error when sending message to topic conduktor_topic with key: null, value: 1 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)                                                                  
org.apache.kafka.common.errors.PolicyViolationException: Client connections exceed the limitation
```
