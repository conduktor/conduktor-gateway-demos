# Conduktor Proxy Failover Demo

## Seamless failover between clusters

Conduktor Gateway's merged clusters feature allows you to assemble resource in the Gateway from a number of different backing Kafka clusters. One use case fo this technology is for failover, the Gateway can be aware of a production and DR cluster and seamlessly switch applications between them with no application downtime.

This example demonstrates 2 clusters and an application moviung between them.

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of two kafka clusters. Each cluster has:

  * A single Zookeeper Server
  * A 2 node Kafka cluster

Also available is:

  * A single Conduktor Proxy container
  * A Kafka Client container (this provides nothing more than a place to run kafka client commands)
  * A Replicator - this is copying data from the prod cluster to the dr cluster to ensure it is ready for failover

### Step 2: Start the environment

Start the environment using:

```bash
docker-compose up -d zookeeper_dr zookeeper_prod kafka1_dr kafka1_prod kafka2_dr kafka2_prod kafka-client
sleep 10
docker-compose up -d conduktor-proxy replicator
sleep 5
echo "Environment started"
```

### Step 3: Create topics

Create the same topic on each of the backing kafka clusters, this represents a live data replication flow. In real cases this would be provided by a replication framework such as Mirror Maker 2 or Confluent Replicator.

For the purpose of clarity and to minimise demo resource usage we simulate this replication flow today.

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1_prod:19092 \
    --create --if-not-exists \
    --partitions 1 \
    --topic resilient_topic
```

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1_dr:9092 \
    --create --if-not-exists \
    --partitions 1 \
    --topic resilient_topic
```

### Step 3: Make Conduktor Gateway aware of the topic

Now that everything is set up let's include Conduktor Gateway, the command below registers `resilient_topic` with Gateway. We specify a topic name and a cluster name for this topic. It is this decoupling of Gateway representation from Kafka representation that makes seamless failover possible.

The final configuration option is flag to say this is a virtual topic. This indicates to Gateway that the topic should not be considered as tied to a specific Kafka cluster. Offsets and other metadata will be managed by Gateway to ensure they are not lost in the event a backing Kafka cluster is killed.

```bash
docker-compose exec kafka-client curl \
  -X POST \
  -H "content-type:application/json" \
  -H "authorization:Basic bm9uZTpub25l" \
  'conduktor-proxy:8888/topicMappings/passThroughTenant/resilient_topic' \
  -d '{ "clusterId" : "prod", "topicName":"resilient_topic", "isVirtual": true}' 
```
The final step is to register the topic with our Gateway tenant

```bash
docker-compose exec kafka-client curl \
  -X POST \
  -H "content-type:application/json" \
  -H "authorization:Basic bm9uZTpub25l" \
  'conduktor-proxy:8888/topics/passThroughTenant' -d '{"name":"resilient_topic"}'
```

Let's list our newly created topic

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --list
```

### Step 4: Produce and replicate

Let's produce a messages into our topic. A client produces messages to Gateway, gateway passes them on to the prod cluster and a replicator copyies them to dr.

```bash
for a in {1..5}; do echo "someRecord$a" | docker-compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server conduktor-proxy:6969 \
        --topic resilient_topic \
; done
```

We can ensure the messages have been routed correctly by checking the backing cluster topics

```bash
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server kafka1_prod:19092 \
        --from-beginning \
        --max-messages 5 \
        --topic resilient_topic 
```

```bash
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server kafka1_dr:9092 \
        --from-beginning \
        --max-messages 5 \
        --topic resilient_topic 
```

Replicator sucks so we may need to bounce it

```bash
docker-compose restart replicator
```

### Step 5: Read data through Gateway

Let's confirm we can read data from the topic with Gateway

```bash
docker-compose exec kafka-client \
kafka-console-consumer  \
--bootstrap-server conduktor-proxy:6969 \
--from-beginning \
--topic resilient_topic
```
### Step 6: Start an application to persist through failover

In separate terminals we will simulate 2 applications that should stay alive during failover:

A consumer

```bash
docker-compose exec kafka-client \
kafka-console-consumer  \
--bootstrap-server conduktor-proxy:6969 \
--from-beginning \
--topic resilient_topic
```
A producer

```bash
docker-compose exec -T kafka-client \
kafka-console-producer  \
--bootstrap-server conduktor-proxy:6969 \
--topic resilient_topic
````

### Step 7: Produce through Gateway (pre-failover)

Before failing over produce a message through Gateway using the terminal above. You will see this appear on the consuming application.

### Failover!

Now we will repoint `resilient_topic` from prod to dr. To do this we first delete the existing mapping and then create a new mapping pointing to dr (Gateway requires some naming conventions, main==dr). 

```bash
docker-compose exec kafka-client curl \
-X DELETE \
-H "content-type:application/json" \
-H "authorization:Basic bm9uZTpub25l" \
'conduktor-proxy:8888/topicMappings/passThroughTenant/resilient_topic'
```

```bash
docker-compose exec kafka-client curl \
  -X POST \
  -H "content-type:application/json" \
  -H "authorization:Basic bm9uZTpub25l" \
  'conduktor-proxy:8888/topicMappings/passThroughTenant/resilient_topic' \
  -d '{ "clusterId" : "main", "topicName":"resilient_topic", "isVirtual": true}' 
```

You may see some warnings in the console terminal. These are normal and indicate the application has seen a failover in progress but has not exited.

### Step 8: Produce post failover

Again using our producing application terminal, produce to resilient_topic, once more it will show in the consuming application indicating that these applications have persisted through a failover. 

### Step 9: Verify backing topics

We can see from the backing clusters that the failover was successful. The dr cluster should contain extra messages that were written after the cluster has failed over. Since replicator is replicating from prod -> dr only these will not be present on the prod cluster.

```bash
docker-compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server kafka1_prod:19092 \
    --topic resilient_topic \
    --from-beginning 
```

```bash
docker-compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server kafka1_dr:9092 \
    --topic resilient_topic \
    --from-beginning 
```

### Step 10: End the demo

Before ending the demo, why not fail back?

To end the demo and clean up the running containers bring the docker environment down:

```bash
docker-compose down
```