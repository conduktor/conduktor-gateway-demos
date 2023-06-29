# Produce Safeguard

In this demo, we will impose rules to ensure that every message coming to kafka is exactly what we want it to be. My environment requires that all producers are configured with acks=0 or 1 and that all messages have headers.

### Video

[![asciicast](https://asciinema.org/a/QOreVnTmGxdo6eMPDeXtUqIxx.svg)](https://asciinema.org/a/QOreVnTmGxdo6eMPDeXtUqIxx)

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
# setup environment
docker-compose up -d zookeeper kafka1 kafka2 kafka-client
sleep 10
docker-compose up -d conduktor-proxy
sleep 5
echo "Environment started"
```

### Step 4: Create a topic

We create topics using the Kafka console tools, the below creates a topic named `safeguardTopic`

```bash
# Create a topic
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic safeguardTopic
```

List the created topic

```bash
# Check it has been created
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --list
```

### Step 5: Configure safeguard

Conduktor Proxy provides a REST API used to configure the safeguard feature.

```bash
# Configure safeguard
docker-compose exec kafka-client curl \
    -u superUser:superUser \
    --request POST "conduktor-proxy:8888/tenant/someTenant/feature/guard-produce" \
    --header 'Content-Type: application/json' \
    --data-raw '{
                  "config": {
                    "acks": [0, 1],
                    "recordHeaders": {
                      "type": "REQUIRED",
                      "filter": "ALL_MATCH"
                    },
                    "compressions": ["ZSTD"]
                  },
                  "direction": "REQUEST",
                  "apiKeys": "PRODUCE"
                }'
```

### Step 6: Produce an invalid message

Next we try to produce message to safeguardTopic with a specification that does not match the above.

```bash
# Now, produce an invalid message
echo 'value' | docker-compose exec -T kafka-client \
    kafka-console-producer \
    --bootstrap-server conduktor-proxy:6969 \
    --producer.config /clientConfig/proxy.properties \
    --topic safeguardTopic
```

You should see an output similar to the following:

```bash
ERROR Error when sending message to topic safeguardTopic with key: null, value: 5 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)                                                                                         
org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Headers are required, offset=0. Invalid value for 'acks': -1. Valid value is one of the values: 0, 1
```

### Step 7: Produce a valid message

```bash
# produce valid messages
echo "headerKey:headerValue\tkey\tvalue" | docker-compose exec -T kafka-client \
    kafka-console-producer \
    --bootstrap-server conduktor-proxy:6969 \
    --producer.config /clientConfig/proxy.properties \
    --topic safeguardTopic \
    --property parse.key=true \
    --property parse.headers=true \
    --request-required-acks=1 \
    --compression-codec zstd
```

Consume message
```bash
docker-compose exec kafka-client \
    kafka-console-consumer \
    --bootstrap-server conduktor-proxy:6969 \
    --consumer.config /clientConfig/proxy.properties \
    --topic safeguardTopic \
    --from-beginning \
    --property print.key=true \
    --property print.headers=true
```
### Step 8: Log into the platform

> The remaining steps in this demo require a Conduktor Platform license. For more information on this [Arrange a technical demo](https://www.conduktor.io/contact/demo)

Once you have a license key, place it in `platform-config.yaml` under the key: `license` e.g.:

```yaml
license: "eyJhbGciOiJFUzI1NiIsInR5cCI6I..."
```

the start the Conduktor Platform container:

```bash
docker-compose up -d conduktor-platform
```

From a browser, navigate to `http://localhost:8080` and use the following to log in (as specified in `platform-config.yaml`):

Username: bob@conduktor.io
Password: admin

### Step 9: View the clusters in Conduktor Platform

From Conduktor Platform navigate to Admin -> Clusters, you should see 2 clusters as below:

![clusters](images/clusters.png "Clusters")

### Step 10: View messages in topic with Conduktor Platform

Navigate to `Console` and select the `Proxy` cluster from the top right.
You should now see the safeguardTopic topic and clicking on it.

You should see an output similar to the following:

![Produce safeguard](images/produce_safeguard.png "Produce safeguard")
