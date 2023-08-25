# Virtual SQL Topic Demo

## What is a virtual topic?

Conduktor Gateway's virtual topics allow you to create a "virtual" copy of an existing Kafka topic that can then 
have interceptors applied to it without affecting the original topic. 

For instance, I may have a topic 'cars' that contains information on cars of all colors, and an application that is only 
interested in Red cars. To satisfy this requirement I can create a virtual topic 'redCarVirtualTopic' which filters out all but the red car data.

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
docker compose up --wait --detach
```

### Step 3: Create source topic

Create our topic cars to have all car data.

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic cars \
    --replication-factor 1 \
    --partitions 1
```
### Step 4: Create the virtual topic interceptor
Let's create the interceptor to filter out the red cars from the all cars.

```bash
# Create the interceptor in Gateway
docker compose exec kafka-client curl \
    -u "admin:conduktor" \
    --request DELETE "conduktor-gateway:8888/admin/interceptors/v1/vcluster/admin/interceptor/red-cars-virtual-topic" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.VirtualSqlTopicPlugin",
        "priority": 1,
        "config": {
            "virtualTopic": "redCars",
            "statement": "SELECT type, price as price FROM cars WHERE color = '"'red'"'"
        }
    }'
```

and let's create the virtual topic.

```bash
# Create the virtual topic
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create \
    --topic redCars \
    --if-not-exists \
    --replication-factor 1 \
    --partitions 1
```

### Step 5: Produce sample data to the all cars topic

Produce 2 records to the underlying topic, our mock car data for cars, a red and blue car.

```bash
echo '{ 
    "type": "Sports",
    "price": 75,
    "color": "blue" 
}' | jq -c | docker compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server conduktor-gateway:6969 \
        --producer.config /clientConfig/gateway.properties \
        --topic cars
echo '{ 
    "type": "SUV",
    "price": 55,
    "color": "red" 
}' | jq -c | docker compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server conduktor-gateway:6969 \
        --producer.config /clientConfig/gateway.properties \
        --topic cars
```

Let's confirm the 2 records are there by consuming from the all cars topic:

```bash
docker compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic cars \
        --from-beginning  \
        --max-messages 2
```

### Step 6: Consume from the virtual topic

Let's consume from our virtual topic `redCars`.

```bash
docker compose exec kafka-client \
    kafka-console-consumer  \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic redCars \
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