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
docker-compose up --wait --detach
```

### Step 3: Create topics

In this demo we will create a cluster that consists of a single unconcentrated topic from the source cluster and 2 
concentrated topics. Let's start by creating topics.

Create the underlying source topic, on the backing Kafka.

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --create --if-not-exists \
    --topic sourceTopic \
    --replication-factor 1 \
    --partitions 1
```

We don’t need to create the physical topic that backs the concentrated topics, it will automatically be created when a client
topic starts using the concentrated topic. We only have to tell Gateway how to map client topics to concentrated topics. In this case, any 
client topic ending "concentrationTest" will be concentrated to the "concentrationTest_topic".

```bash
docker-compose exec kafka-client \
  curl \
    --user "superUser:superUser" \
    --request POST 'conduktor-gateway:8888/admin/vclusters/v1/vcluster/someCluster/topics/.%2AconcentrationTest' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "physicalTopicName": "concentrationTest_topic",
        "readOnly": false,
        "concentrated": true
    }'
```

Now let's create the logical topics

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create \
    --topic times10_concentrationTest \
    --replication-factor 1 \
    --partitions 1
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create \
    --topic times100_concentrationTest \
    --replication-factor 1 \
    --partitions 1
```

If we list topics from the backend cluster, not from Gateway perspective, now we see 2 topics. The source topic and the concentrated topic (created by Gateway).

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --list
```

From the Gateway side, or client perspecitve, we also see 2 topics but these are the logical topics.

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --list
```

We need `sourceTopic` to be available to our cluster but currently it is not shown. To add it we need to create an 
unconcentrated **mapping**. Previously we created a concentrated mapping between Gateway and the backing cluster. 

This regular mapping allows our virtual cluster to see the topic on the backing cluster.

```bash
docker-compose exec kafka-client\
  curl \
    --user "superUser:superUser" \
    --request POST 'conduktor-gateway:8888/admin/vclusters/v1/vcluster/someCluster/topics/sourceTopic' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "physicalTopicName": "sourceTopic",
        "readOnly": false,
        "concentrated": false
    }'
```

Now the Gateway listing shows sourceTopic too

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --list
```

### Step 4: Produce data to the underlying topic

Now we will produce 20 records to the physical topic, the one on the backing cluster.
and read it back through the Gateway.

```bash
seq 1 20 | jq -c | docker-compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server kafka1:9092 \
        --topic sourceTopic
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic sourceTopic \
        --from-beginning \
        --max-messages 20
```

### Step 5: Run our applications

These example applications run completely through Gateway and require no access to the underlying Kafka.
One example application multiplies each message in sourceTopic by 10, and emits the result to times10_concentrationTest. 
The other multiplies by 100 and emits the result to times100_concentrationTest.

```bash
docker-compose exec kafka-client \
     kafka-console-consumer \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic sourceTopic \
         --from-beginning \
         --max-messages 20 \
         | sed -e 's/$/0/' \
         | docker-compose exec -T kafka-client \
         kafka-console-producer \
            --bootstrap-server conduktor-gateway:6969 \
            --producer.config /clientConfig/gateway.properties \
            --topic times10_concentrationTest

docker-compose exec kafka-client \
     kafka-console-consumer \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic sourceTopic \
         --from-beginning \
         --max-messages 20 \
         | sed -e 's/$/00/' \
         | docker-compose exec -T kafka-client \
         kafka-console-producer \
            --bootstrap-server conduktor-gateway:6969 \
            --producer.config /clientConfig/gateway.properties \
            --topic times100_concentrationTest 
```


### Step 6: Confirm the results

We can query the data in the client topics to confirm

```bash
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic times10_concentrationTest \
        --from-beginning \
        --max-messages 20 

docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic times100_concentrationTest \
        --from-beginning \
        --max-messages 20
```

### Step 7: View the underlying concentrated topic

If we consume the concentrated topic directly we see both client topic's messages

```bash
docker-compose exec kafka-client \
kafka-console-consumer  \
--bootstrap-server kafka1:9092 \
--topic concentrationTest_topic \
--from-beginning \
--max-messages 40
```
# Conclusion
We have reviewed how to make the most of your existing topics through topic concentration.
We created a concentrated topic, with rules for which virutal topics it will power.
We created virtual topics that will use the underlying concentrated topic, then demo'd producing to them as apps and consuming the data back.
Finally we also had a look at the underlying topic in the backing cluster to show you the magic.

These are a sample of the types of situations that can be simulated, if you have others or more detailed scenarios you'd want to simualte then [get in touch](https://www.conduktor.io/contact/demo), we'd love to speak with you. 
