# Virtual SQL Topic Demo

## What is a virtual topic?

Conduktor Gateway's virtual topics allow you to create a "virtual" copy of an existing Kafka topic that can then
have interceptors applied to it without affecting the original topic.

For instance, I may have a topic 'cars' that contains information on cars of all colors, and an application that is only
interested in Red cars. To satisfy this requirement I can create a virtual topic 'red-car' which filters out all but the red car data.

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

Create our topic `cars` to have all car data.

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

### Step 4: Produce sample data to cars topic

Produce 2 records to the `cars` topic, our mock car data for cars,

A blue car.

(We use `jq` for readability, if you don't have this installed remove simply the `| jq` from the below command.)

```bash
echo '{
    "type": "Sports",
    "price": 75,
    "color": "blue"
}' | jq -c | docker compose exec -T kafka-client \
    kafka-console-producer \
        --bootstrap-server conduktor-gateway:6969 \
        --producer.config /clientConfig/gateway.properties \
        --topic cars
```

And a red car

```bash
echo '{
    "type": "SUV",
    "price": 55,
    "color": "red"
}' | jq -c | docker compose exec -T kafka-client \
    kafka-console-producer \
        --bootstrap-server conduktor-gateway:6969 \
        --producer.config /clientConfig/gateway.properties \
        --topic cars
```

Let's confirm the 2 records are there by consuming from the all cars topic:

```bash
docker compose exec kafka-client \
    kafka-console-consumer \
        --bootstrap-server conduktor-gateway:6969 \
        --consumer.config /clientConfig/gateway.properties \
        --topic cars \
        --from-beginning \
        --max-messages 2 | jq
```

### Step 5: Create the virtual topic interceptor
Let's create the interceptor to filter out the red cars from the all cars.

```bash
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/red-cars-virtual-topic" \
    --header "Content-Type: application/json" \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.VirtualSqlTopicPlugin",
        "priority": 100,
        "config": {
            "virtualTopic": "red-cars",
            "statement": "SELECT type as redType, price FROM cars WHERE color = '"'red'"'"
        }
    }'
```

Make sure it is saved

```bash
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request GET "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/red-cars-virtual-topic" | jq
```


### Step 6: Consume from the virtual topic

Let's consume from our virtual topic `red-cars`.

```bash
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/gateway.properties \
    --topic red-cars \
    --from-beginning \
    --max-messages 1 | jq
```

You should see only one message consumed with the format changed according to our SQL statement's projection.

```json
{
  "type":"SUV",
  "color":"red"
}
```

### Step 7: Cleaning up

You can delete the interceptor on the virtual topic, the virtual topic will no more be accessible.

```bash
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request DELETE "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/red-cars-virtual-topic"
```