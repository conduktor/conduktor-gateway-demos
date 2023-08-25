# Create Topic Policy Demo

In this demo we will impose limits on topic creation to ensure that any topics created in the cluster adhere to a minimum specification for Replication Factor and Partition count.

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Gateway container
* A Conduktor Console container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Review the Console configuration

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

### Step 4: Configure safeguard

Conduktor gateway provides a REST API used to configure the interceptors.

The command below will instruct Conduktor Gateway to enforce a minimum of 2 replicas and 3 partitions for any newly created topics. Leaving `topic` blank applies this to all topics on the tenant.

```bash
docker-compose exec kafka-client \
curl \
    --user "admin:conduktor" \
    --request POST conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/users/someUser/interceptors/guard-create-topics \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.safeguard.CreateTopicPolicyPlugin",
        "priority": 100,
        "config": { 
            "topic": "",
            "minNumPartition": 3,
            "maxNumPartition": 3,
            "minReplicationFactor": 2,
            "maxReplicationFactor": 2 
        }
    }'
```

### Step 5: Attempt to create an invalid topic

Next we try to create a topic with a specification that does not match the above, too many partitions.

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create \
    --topic invalidTopic \
    --replication-factor 1 \
    --partitions 10
```

You should see an output similar to the following:

```bash
Error while executing topic command : Request parameters do not satisfy the configured policy. Number partitions is '10', must not be greater than 3. Replication factor is '1', must not be less than 2
```
### Step 6: Create a valid topic

If we modify our command to meet the criteria the topic is created.

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create \
    --topic validTopic \
    --replication-factor 2 \
    --partitions 3
```
### Step 7: Visualise the workflow

> To take part in the remaining steps in this demo require a Conduktor Console license. For more information on this visit the [Console page](https://www.conduktor.io/console/) or [contact us](https://www.conduktor.io/contact/). 
> Without a license you can follow along how you can visualise what we did today in Console. Please note the UI may change as we're constantly improving.
### Step 8: View the clusters in Conduktor Console

From Conduktor Console you can see the 2 clusters as below:

![clusters](images/clusters.png "Clusters")

### Step 9: Attempt to create an invalid topic with Conduktor Console

Navigate to `Console` and select the `Gateway` cluster from the top right, with the `validTopic` created earlier.

Clicking the `Create Topic` button and filling out invalid topic details once more:

* name: invalidTopic
* Partitions: 1
* Replication Factor: 1

Will produce the error in topic creation as before:

![create a topic](images/invalid_topic.png "Attempt to create an invalid topic")

# Conclusion
We have reviewed an important part of any Kafka setup, safeguarding from the creation of crazy topics. This gives central teams the tools they need to enable self-serve capability project teams within the guardrails they want to put in place.