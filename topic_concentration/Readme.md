# Conduktor Proxy Topic Concentration Demo

## What is Topic Concentration?

Conduktor Gateway's topic concentration feature allows you to store multiple topics's data on a single underlying Kafka 
topic. To clients, it appears that there are multiple topics and these can be read from as normal but in the underlying 
Kafka cluster there is a lot less resource required.

For instance, I may see topics "times10_concentrationTest" and "times100_concentrationTest" in Gateway that are both stored on the 
underlying "concentrationTest_topic".

## Running the demo
In this demo we are going to create a concentrated topic for powering several virtual topics. Create the virtual topics, produce and consume data to them, and explore how this works.

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Gateway container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Start the environment

Start the environment with

```bash
docker compose up --wait --detach
```

### Step 3: Create underlying topic

In this demo we will create a cluster that consists of a single unconcentrated topic from the source cluster and 2 concentrated topics. 

Let's start by creating topics.

Create the underlying `hold-many-virtual-topics` topic on the backing Kafka.

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --create --if-not-exists \
    --topic hold-many-virtual-topics \
    --replication-factor 1 \
    --partitions 10
```

We don’t need to create the physical topic that backs the concentrated topics, it will automatically be created when a client topic starts using the concentrated topic. 
We only have to tell Gateway how to map client topics to concentrated topics. 
In this case, any  client topic started with `concentrated-` will be concentrated to the `hold-many-virtual-topics`.

```bash
docker-compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request POST 'conduktor-gateway:8888/admin/vclusters/v1/vcluster/someCluster/topics/concentrated-.%2A' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "physicalTopicName": "hold-many-virtual-topics",
        "readOnly": false,
        "concentrated": true
    }'
```

### Step 4: Create concentrated topics

Now let's create logical topics

One with 10 partitions

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create \
    --topic concentrated-topic-with-10-partitions \
    --replication-factor 1 \
    --partitions 10
```

Another one with 100 partitions

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create \
    --topic concentrated-topic-with-100-partitions \
    --replication-factor 1 \
    --partitions 100
```

If we list topics from the backend cluster, not from Gateway perspective, we do not see the concentrated topics. 

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --list
```

From the Gateway side, or client perspective, we also see 2 topics but these are the logical topics.

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --list
```

### Step 4: Confirm they are regular topics

We can send and query the data in the concentrated topics 

```bash
echo '{"type": "Sports", "price": 75, "color": "blue"}' | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
        --bootstrap-server conduktor-gateway:6969 \
        --producer.config /clientConfig/gateway.properties \
        --topic concentrated-topic-with-10-partitions
```

```bash
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic concentrated-topic-with-10-partitions \
        --from-beginning \
        --max-messages 1 | jq
```

Same for `concentrated-topic-with-100-partitions`

```bash
echo '{"msg": "hello world"}' | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
        --bootstrap-server conduktor-gateway:6969 \
        --producer.config /clientConfig/gateway.properties \
        --topic concentrated-topic-with-100-partitions
```

```bash
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic concentrated-topic-with-100-partitions \
        --from-beginning \
        --max-messages 1 | jq
```

### Step 7: View the underlying concentrated topic

If we consume the concentrated topic directly we see both client topic's messages

```bash
docker-compose exec kafka-client \
  kafka-console-consumer  \
    --bootstrap-server kafka1:9092 \
    --topic hold-many-virtual-topics \
    --from-beginning \
    --max-messages 2 | jq
```

### Step 8: Revealing the magic

In order to understand the magic behind the concentration feature, let's inspect the headers

```bash
docker-compose exec kafka-client \
  kafka-console-consumer  \
    --bootstrap-server kafka1:9092 \
    --topic hold-many-virtual-topics \
    --property print.headers=true \
    --property print.partition=true \
    --from-beginning \
    --max-messages 2
```

We are saving information as metadata in headers to be able to honor kafka semantic when vclusters request data.


# Conclusion

We have reviewed how to make the most of your existing topics through topic concentration.

We created a concentrated topic, with rules for which virutal topics it will power.

We created virtual topics that will use the underlying concentrated topic, then demo'd producing to them as apps and consuming the data back.

Finally we also had a look at the underlying topic in the backing cluster to show you the magic.

These are a sample of the types of situations that can be simulated, if you have others or more detailed scenarios you'd want to simulate then [get in touch](https://www.conduktor.io/contact/demo), we'd love to speak with you. 
