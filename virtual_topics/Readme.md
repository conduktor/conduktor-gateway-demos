# Virtual SQL Topic Demo

## What is A virtual topic?

Conduktor Gateway's virtual topics allow you to create a "virtual" copy of an existing Kafka topic that can then 
have interceptors applied to it without affecting the original topic. 

For instance, I may have a topic 'cars' that contains information on cars of all colors, and an application that is only 
interested in Red cars. To satisfy this requirement I can create a virtual topic 'redCars' and apply a filter to this 
topic so that only blue car data is available.

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Gateway container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Start the environment

Start the environment with

```bash
docker compose up -d
```

### Step 3: Create source topic

We create an existing topic in the Kafka cluster, this will form the basis of our virtual topic. 

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --create --if-not-exists \
    --topic carsTopic \
    --replication-factor 1 \
    --partitions 1
```
### Step 4: Create the virtual topic template interceptor, and the virtual topic
Next we create the virtual topic. This is a 2 step process, first we must create a template for the virtual topic that defines 
the underlying topic it will source it's data from, and then use this template to create the virtual topic. 

```bash
# Create the template in Gateway
docker compose exec kafka-client curl \
    -u "admin:conduktor" \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/tenants/someTenant/users/someUser/interceptors/redCarVirtualTopicTemplate" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.VirtualSqlTopicPlugin",
        "priority": 100,
        "config": {
            "virtualTopic": "redCarVirtualTopic",
            "statement": "SELECT type, price as price FROM cars WHERE color = 'red'"
        }
    }'

# Create the virtual topic
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create \
    --topic red-cars \
    --if-not-exists \
    --replication-factor 1 \
    --partitions 1
```

### Step 5: Produce data to the underlying topic

Now we will produce 2 records to the underlying topic

```bash
echo '{ 
    "type": "Sports",
    "price": 75,
    "color": "blue" 
}' | jq -c | docker compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server kafka1:9092 \
        --topic sourceTopic
echo '{ 
    "type": "SUV",
    "price": 55,
    "color": "red" 
}' | jq -c | docker compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server kafka1:9092 \
        --topic sourceTopic
```

Let;s confirm the 2 records are there by consuming from the source topic:

```bash
docker compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server kafka1:9092 \
        --topic sourceTopic \
        --from-beginning  
```

### Step 6: Consume from the topic

Let's consume from our virtual topic `red-cars`.

```bash
docker compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic red-cars \
        --from-beginning  
```

You should see only one message consumed with the format changed according to our SQL statement's projection.

```json
{"type":"SUV","color":"red"}

```

### Step 7: Cleaning up

You can delete the interceptor on the virtual topic and once more you will see 2 records when consuming:

```bash
docker compose exec kafka-client curl \
    -u "superUser:superUser" \
    -vvv \
    --request DELETE "conduktor-gateway:8888/tenant/someTenant/feature/sql-filter/apiKeys/FETCH/direction/RESPONSE" \
    --header 'Content-Type: application/json' 
    
```