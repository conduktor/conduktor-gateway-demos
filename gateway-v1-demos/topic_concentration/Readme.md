# Conduktor Proxy Topic Concentration Demo

## What is Topic Concentration?

Conduktor Proxy's topic concentration feature allows you to store multiple topics's data on a single underlying Kafka 
topic. To clients, it appears that there are multiple topics and these can be read from as normal but in the underlying 
Kafka cluster there is a lot less resource requirement.

For instance, I may see topics "times10_testTenant" and "times100_testTenant" in Gateway that are both stored on the 
underlying "testTenant_topic"

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Proxy container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Start the environment

Start the environment with

```bash
docker-compose up -d  zookeeper kafka-client kafka2 kafka1 schema-registry
sleep 10
docker-compose up -d conduktor-proxy
sleep 5
echo "Environment started" 
```

### Step 3: Create topics

In this demo we will create a tenant that consists of a single unconcentrated topic from the source cluster and 2 
concentrated topics. Let's start by creating topics.

The underlying source topic

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --create --if-not-exists \
    --topic sourceTopic \
    --replication-factor 1 \
    --partitions 1
```

We don't need to create the topic that backs the concentrated topics, it will automatically be created when any client 
topic using it is. We only have to tell Gateway how to map client topics to concentrated topics. In this case, any 
client topic ending "testTenant" will be concentrated to "testTenant_topic"

```bash
docker-compose exec kafka-client curl \
    -vvv \
    -u "superUser:superUser" \
    --request POST 'conduktor-proxy:8888/topicMappings/someTenant/.*testTenant' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "topicName": "testTenant_topic",
        "isConcentrated": true
    }'

```

Now let's create the client topics

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create \
    --topic times10_testTenant \
    --replication-factor 1 \
    --partitions 1
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create \
    --topic times100_testTenant \
    --replication-factor 1 \
    --partitions 1
```

If we list topics from the backend cluster now we see 2 topics. Source topic and the concentrated topic

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --list
```

From Gateway we also see 2 topics but these are the client topics.

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --list
```

We need sourceTopic to be available to our tenant but currently it is not shown. To add it we need to create an 
unconcentrated mapping that covers it

```bash
docker-compose exec kafka-client curl \
    -vvv \
    -u "superUser:superUser" \
    --request POST 'conduktor-proxy:8888/topicMappings/someTenant/sourceTopic' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "topicName": "sourceTopic"
    }'
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create \
    --topic sourceTopic \
    --replication-factor 1 \
    --partitions 1
```

Now the Gateway listing shows sourceTopic too

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --list
```

### Step 4: Produce data to the underlying topic

Now we will produce 20 records to the underlying topic

```bash
seq 1 20 | jq -c | docker-compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server kafka1:9092 \
        --topic sourceTopic
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-proxy:6969 \
        --consumer.config /clientConfig/proxy.properties \
        --topic sourceTopic \
        --from-beginning 
```

### Step 5: Run our applications

These applications run completely through Gateway and require no access to the underlying Kafka. One multiplies each 
message in sourceTopic by 10 and emits the result to times10_testTenant and the other multiplies by 100 and emits the 
result to times100_testTenant.

```bash
docker-compose exec kafka-client \
     kafka-console-consumer \
        --bootstrap-server conduktor-proxy:6969 \
        --consumer.config /clientConfig/proxy.properties \
        --topic sourceTopic \
         --from-beginning \
         --max-messages 20 \
         | sed -e 's/$/0/' \
         | docker-compose exec -T kafka-client \
         kafka-console-producer \
            --bootstrap-server conduktor-proxy:6969 \
            --producer.config /clientConfig/proxy.properties \
            --topic times10_testTenant 
docker-compose exec kafka-client \
     kafka-console-consumer \
        --bootstrap-server conduktor-proxy:6969 \
        --consumer.config /clientConfig/proxy.properties \
        --topic sourceTopic \
         --from-beginning \
         --max-messages 20 \
         | sed -e 's/$/00/' \
         | docker-compose exec -T kafka-client \
         kafka-console-producer \
            --bootstrap-server conduktor-proxy:6969 \
            --producer.config /clientConfig/proxy.properties \
            --topic times100_testTenant 
```


### Step 6: Confirm the results

We can query the data in the client topics to confirm

```bash
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-proxy:6969 \
        --consumer.config /clientConfig/proxy.properties \
        --topic times10_testTenant \
        --from-beginning
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-proxy:6969 \
        --consumer.config /clientConfig/proxy.properties \
        --topic times100_testTenant \
        --from-beginning
```

### Step 7: View the underlying concentrated topic

If we consume the concentrated topic we see both client topic's messages

```bash
docker-compose exec kafka-client \
kafka-console-consumer  \
--bootstrap-server kafka1:9092 \
--topic testTenant_topic \
--from-beginning
```
