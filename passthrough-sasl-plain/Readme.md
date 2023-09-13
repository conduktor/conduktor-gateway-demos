# Applying interceptors in Passthrough mode

## What is Passthrough mode?

This is the default mode, it's when you want to complement your existing kafka, without having the multi-tenancy features of Conduktor Gateway

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster with sasl_plaintext
* A single Conduktor Gateway container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Start the environment

Start the environment with

```bash
docker compose up --wait --detach
```

### Step 3: Configure plugin

Please note that the `vcluster` is the username

```bash
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request POST conduktor-gateway:8888/admin/interceptors/v1/vcluster/admin/interceptor/broken-plugin \
    --header "Content-Type: application/json" \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateBrokenBrokersPlugin",
        "priority": 100,
        "config": {
            "rateInPercent": 50,
            "errorMap": {
                "FETCH": "UNKNOWN_SERVER_ERROR",
                "PRODUCE": "CORRUPT_MESSAGE"
            }
          }
        }'
```

# Step 4: Create a topic

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --topic chaos-example \
    --create  
```

# Step 5: Write a message in chaos-example

```bash
docker-compose exec kafka-client \
  kafka-producer-perf-test \
      --producer.config /clientConfig/gateway.properties \
      --record-size 10 \
      --throughput 10 \
      --num-records 100 \
      --topic chaos-example
```


