# Limit client Safeguard Demo

In this demo we will impose protecting cluster by limiting client calls to produce or fetch data

### Video

[![asciicast](https://asciinema.org/a/qw1O5phcqkoF3XLRZkan7cUR7.svg)](https://asciinema.org/a/qw1O5phcqkoF3XLRZkan7cUR7)

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

Conduktor Proxy provides a REST API used to configure the safeguard feature to limit 1 client call only to produce data in 10 seconds

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/feature/guard-limit-client" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
            "idAndPartitions": [
              {"brokerId":1,"partitions":[0]},
              {"brokerId":2,"partitions":[0]}
            ],
            "callsLimit": 1,
            "duration": 10,
            "durationUnit": "SECONDS"
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```

### Step 6: Attempt to call to produce data

Let's produce to the `conduktor_topic` topic

```bash
echo 'testMessage' | docker-compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server conduktor-proxy:6969 \
        --producer.config /clientConfig/proxy.properties \
        --topic conduktor_topic
```

Let's produce to the `conduktor_topic` topic again

```bash
docker-compose exec kafka-client \
    kafka-console-producer  \
        --bootstrap-server conduktor-proxy:6969 \
        --producer.config /clientConfig/proxy.properties \
        --topic conduktor_topic
```

You should see an output similar to the following in the terminal right after you enter the message

```bash
ERROR Error when sending message to topic conduktor_topic with key: null, value: 1 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Client calls produce exceed the limitation
```

Conduktor Proxy provides a REST API used to configure the safeguard feature to limit 1 client call only to consume data in 20 seconds

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/feature/guard-limit-client" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
            "idAndPartitions": [
              {"brokerId":1,"partitions":[0]},
              {"brokerId":2,"partitions":[0]}
            ],
            "callsLimit": 1,
            "duration": 20,
            "durationUnit": "SECONDS"
        },
        "direction": "REQUEST",
        "apiKeys": "FETCH"
    }'
```

### Step 6: Attempt to call to consume data

Let's consume data from the `conduktor_topic` topic

```bash
docker-compose exec kafka-client kafka-console-consumer \
  --bootstrap-server conduktor-proxy:6969 \
  --consumer.config /clientConfig/proxy.properties \
  --from-beginning \
  --max-messages 1 \
  --topic conduktor_topic
```
You should see an output similar to the following in the terminal right after you enter the message

Let's consume data from the `conduktor_topic` topic again

```bash
docker-compose exec kafka-client kafka-console-consumer \
  --bootstrap-server conduktor-proxy:6969 \
  --consumer.config /clientConfig/proxy.properties \
  --from-beginning \
  --max-messages 1 \
  --topic conduktor_topic
```

You should see an output similar to the following in the terminal but in a latency (about 20 seconds after your first consume call) because error below happened,
and kafka consumer had to retry until successfully

```bash
ERROR Error when sending message to topic conduktor_topic with key: null, value: 1 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.PolicyViolationException: Client calls fetch exceed the limitation
```
