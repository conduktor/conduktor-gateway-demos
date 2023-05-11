# Conduktor Proxy Virtual Topics Demo

## What is A virtual topic?

Conduktor Proxy's virtual topics feature allows you to create a "virtual" copy of an existing Kafka topic that can then 
have interceptors applied to it without affecting the original topic. 

For instance, I may have a topic 'cars' that contains information on cars of all colors and an application that is only 
interested in Blue cars. To satisfy this requirement I can create a virtual topic 'blueCars' and apply a filter to this 
topic so that only blue car data is available.

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

### Step 3: Create source topic

We create an existing topic in the Kafka cluster, this will form the basis of our virtual topic. 

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --create --if-not-exists \
    --topic sourceTopic \
    --replication-factor 1 \
    --partitions 1
```

Next we create the virtual topic. This is a 2 step process, first we must create a template for the topic that defines 
the underlying topic it will source it's data from and then use this template to create the topic. 

```bash
docker-compose exec kafka-client curl \
    -vvv \
    -u "superUser:superUser" \
    --request POST "conduktor-proxy:8888/topicMappings/someTenant/virtualTopic" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "topicName": "sourceTopic",
        "isVirtual": true
    }'
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create \
    --topic virtualTopic \
    --replication-factor 1 \
    --partitions 1
```

### Step 4: Configure filtering

In this demo we will filter personnel records for a single name. To do this we apply a SQL like filter to the virtual 
topic via Conduktor Gateway's interceptor features. 
 
```bash
docker-compose exec kafka-client curl \
    -u "superUser:superUser" \
    -vvv \
    --request POST "conduktor-proxy:8888/tenant/someTenant/feature/sql-filter" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
            "statement": "SELECT '"'"'$.name'"'"' as givenName, '"'"'$.age'"'"' as yearsSinceBirth FROM virtualTopic WHERE '"'"'$.name'"'"' = '"'"'Tom'"'"'"
        },
        "direction": "RESPONSE",
        "apiKeys": "FETCH"
    }'
```

### Step 5: Produce data to the underlying topic

Now we will produce 2 records to the underlying topic

```bash
echo '{ 
    "name": "Tom",
    "age": 38 
}' | jq -c | docker-compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server kafka1:9092 \
        --topic sourceTopic
echo '{ 
    "name": "Mitch",
    "age": 21 
}' | jq -c | docker-compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server kafka1:9092 \
        --topic sourceTopic
```

Let;s confirm the 2 records are there by consuming from the source topic:

```bash
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server kafka1:9092 \
        --topic sourceTopic \
        --from-beginning  
```

### Step 6: Consume from the topic

Let's consume from our virtual topic `virtualTopic`.

```bash
docker-compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-proxy:6969 \
        --consumer.config /clientConfig/proxy.properties \
        --topic virtualTopic \
        --from-beginning  
```

You should see only one message consumed with the format changed according to our SQL statement's projection.

```json
{"originalName":"Tom","yearsSinceBirth":38}

```

### Step 7: Cleaning up

You can delete the interceptor on the virtual topic and once more you will see 2 records when consuming:

```bash
docker-compose exec kafka-client curl \
    -u "superUser:superUser" \
    -vvv \
    --request DELETE "conduktor-proxy:8888/tenant/someTenant/feature/sql-filter/apiKeys/FETCH/direction/RESPONSE" \
    --header 'Content-Type: application/json' 
    
```