# Conduktor Gateway Acls Demo

## What are Conduktor Gateway Acls?

Conduktor Gateway Acls are a reimplementation of Kafka's ACL features in Conduktor Gateway. Using Gateway Acls you can 
configure access restrictions for individual vClusters in Conduktor Gateway.

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Gateway container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)
* A Conduktor Platform container
* A Conduktor Console, our UI for everything Kafka
* A Postgres, required by our UI
* A volume, required by our UI

### Step 2: Review the platform configuration

`platform-config.yaml` defines 2 clusters:

* Backing Kafka - this is a direct connection to the underlying Kafka cluster hosting the demo
* Gateway - a connection through Conduktor Gateway to the underlying Kafka

Note: Gateway and backing Kafka can use different security schemes.
In this case the backing Kafka is PLAINTEXT but the Gateway is SASL_PLAIN.

### Step 3: Start the environment

Start the environment with

```bash
docker compose up --wait --detach
```

### Step 4: Configure Acls

Now let's create an Acl interceptor via the Admin API.

The configuration of this interceptor will enable the Acl features in Gateway.

```bash
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request POST "conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/interceptor/acls" \
    --header "Content-Type: application/json" \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.AclsInterceptorPlugin",
        "priority": 100,
        "config": {}
    }'
```

### Step 4: Create topics

To start let's try (and fail) to create a topic named `someTopic`.

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic someTopic
```

Because Acls are enabled this is denied for our user.

```
Error while executing topic command : Cluster not authorized
[2023-10-24 16:37:09,575] ERROR org.apache.kafka.common.errors.ClusterAuthorizationException: Cluster not authorized
(kafka.admin.TopicCommand$)
```

### Step 5: Add Acls

Let's permit our user to create topics. To do this they require the `Cluster -> Create` Acl and the `Topic -> Create` Acl 
for the desired topic. 

Note that we use a different command-config for these commands. This is because Acls can only be modified by admin 
users on Gateway. 

```bash
docker compose exec kafka-client  \
  kafka-acls \
  --bootstrap-server conduktor-gateway:6969 \
  --command-config /clientConfig/admin.properties \
  --add \
   --allow-principal User:someUsername \
  --operation create \
  --cluster

docker compose exec kafka-client  \
  kafka-acls \
  --bootstrap-server conduktor-gateway:6969 \
  --command-config /clientConfig/admin.properties \
  --add \
   --allow-principal User:someUsername \
  --operation create \
  --topic someTopic 
```

Now let's list the created Acls:

```bash
docker compose exec kafka-client  \
  kafka-acls \
  --bootstrap-server conduktor-gateway:6969 \
  --command-config /clientConfig/admin.properties \
  --list
```

### Step 6: Retry create topics

Now we can create a topic named `someTopic`.

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic someTopic
```

### Step 6: Produce to the topic

We have to add a write Acl before we can produce to the created topic.
Three calls below, `describe`, `write`, `read`.

```bash
docker compose exec kafka-client  \
  kafka-acls \
  --bootstrap-server conduktor-gateway:6969 \
  --command-config /clientConfig/admin.properties \
  --add \
   --allow-principal User:someUsername \
  --operation describe \
  --topic someTopic 
docker compose exec kafka-client  \
  kafka-acls \
  --bootstrap-server conduktor-gateway:6969 \
  --command-config /clientConfig/admin.properties \
  --add \
   --allow-principal User:someUsername \
  --operation write \
  --topic someTopic 
docker compose exec kafka-client  \
  kafka-acls \
  --bootstrap-server conduktor-gateway:6969 \
  --command-config /clientConfig/admin.properties \
  --add \
   --allow-principal User:someUsername \
  --operation read \
  --topic someTopic 
```

Now we can produce!

```bash
echo testMessage | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
      --bootstrap-server conduktor-gateway:6969 \
      --producer.config /clientConfig/gateway.properties \
      --topic someTopic
```

### Step 7: Consume from the topic

Before we can consume we need to add an acl to allow our consumer to form a consumer group.

```bash
docker compose exec kafka-client  \
  kafka-acls \
  --bootstrap-server conduktor-gateway:6969 \
  --command-config /clientConfig/admin.properties \
  --add \
  --allow-principal User:someUsername \
  --operation read \
  --group '*'
```

Now we can consume.

```bash
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/gateway.properties \
    --topic someTopic \
    --from-beginning \
    --max-messages 1
```

# Conclusion
We have today reviewed how you can secure access to your data, utilising Kafka Acl tooling through Conduktor Gateway

This of course is but one of the many features available from the Gateway, for further questions on how Gateway can help take your Kafka experience to the next level [contact us](https://www.conduktor.io/contact/).