# Conduktor Gateway Virtual Cluster (Multi-tenant) Demo

## What is Multi-tenancy?

Conduktor Gateway's multi-tenancy feature allows 1 Kafka cluster to appear as a number of isolated clusters to clients. Each virtual cluster or tenant can be operated upon separately with no concern of side effects for the others.

### Architecture diagram

![architecture diagram](images/multi-tenant.png "multi-tenant")

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Gateway container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Review the platform configuration

For the later part of our demo we discuss how our Conduktor Console was connected to Gateway.

`platform-config.yaml` defines 3 clusters:

* Backing Kafka - this is a direct connection to the underlying Kafka cluster hosting the demo
* London - a connection through Conduktor Gateway that represents the London virtual cluster/tenant
* Paris - a connection through Conduktor Gateway that represents the Paris virtual cluster/tenant

Note: Tenancy is determined by the SASL credentials configured for each cluster.
These credentials provide a token that encodes tenancy information.
See the JWT demo or the docs site for more info.

### Step 3: Start the environment

Start the environment with

```bash
docker compose up --detach

```

### Step 4: Create topics

Let's create some topics using the Kafka console tools.
Below creates a topic name `londonTopic` in virtual cluster `London`

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/london.properties \
    --create --topic londonTopic
```

Below creates a topic name `parisTopic` in virtual cluster `Paris`

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/paris.properties \
    --create --topic parisTopic
```

List all topics from both virtual clusters to see that, although they are hosted on the same underlying cluster, the topics are isolated from eachother:

For `london`

```bash
docker compose exec kafka-client \
    kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/london.properties \
    --list
```

For `paris`

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/paris.properties \
    --list
```

### Step 5: Produce data to the topics

You can produce with the CLI tools as follows:

for `london`

```bash
echo testMessageLondon | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
      --bootstrap-server conduktor-gateway:6969 \
      --producer.config /clientConfig/london.properties \
      --topic londonTopic
```

for `paris`

```bash
echo testMessageParis | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
      --bootstrap-server conduktor-gateway:6969 \
      --producer.config /clientConfig/paris.properties \
      --topic parisTopic
```

### Step 6: Consume from the topics

And consume the messages produced above.

for `london`

```bash
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/london.properties \
    --topic londonTopic \
    --from-beginning \
    --max-messages 1
```

for `paris`

```bash
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/paris.properties \
    --topic parisTopic \
    --from-beginning \
    --max-messages 1
```

You could see how the message `testMessageLondon` cannot be consumed from the `Paris` virtual cluster client due to cluster isolation. 
It is not aware of this topic as it's in a different "cluster".

If you tried to, you would get the `{parisTopic=UNKNOWN_TOPIC_OR_PARTITION}` error until timeout(default 5 minutes).

`WARN [Consumer clientId=console-consumer, groupId=console-consumer-68780] Error while fetching metadata with correlation id 921 : {parisTopic=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)`

### Step 7: Applying Multi-tenancy to existing topics (topic mapping)

During migration to Conduktor Gateway you may want to make up a virtual cluster population from existing topics in your Kafka cluster. 
Conduktor Gateway allows this via the administration APIs through **topic mapping**. 
For more detail on the APIs check the Conduktor docs site.

In this next section we will create topics on the backing Kafka cluster and add them to vclusters within Conduktor Gateway.

Let's start by creating some pre-exiting topics on the backing Kafka cluster and adding data to them.

Let's create `existingLondonTopic` on the underlying kafka.

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --create --if-not-exists \ 
    --topic existingLondonTopic \
```

Let's create `existingSharedTopic` on the underlying kafka.

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --create --topic existingSharedTopic
```

Let's create a message in `existingLondonTopic`

```bash
echo existingLondonMessage | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
    --bootstrap-server kafka1:9092 \
    --topic existingLondonTopic \
```

Let's create a message in `existingSharedTopic`

```bash
echo existingSharedMessage | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
    --bootstrap-server kafka1:9092 \
    --topic existingSharedTopic
```

### Step 8: Configuring vclusters for existing topics

We'll create the following mappings:

* virtualCluster: `London` can see `existingLondonTopic` and `existingSharedTopic`
* virtualCluster: `Paris` can see only `existingSharedTopic`

First we create a topic mapping for each topic. 
These map a topic name for the virtual cluster to a topic name in the backing Kafka cluster. 
These names do not have to match but they match here for clarity.  


First let's add the mapping of the topic name for the London virtual cluster and place in the url parameter,`.../existingLondonTopic`, to the topic name in the backing cluster which is what we have in the payload `"physicalTopicName": "existingLondonTopic"`.

```bash
docker compose exec kafka-client \
 curl \
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/london/topics/existingLondonTopic \
    --user admin:conduktor \
    --header 'Content-Type: application/json' \
    --data-raw '{ 
        "physicalTopicName": "existingLondonTopic",
        "readOnly": false,
        "concentrated": false
        }'
```

and again to add the mapping `existingSharedTopic` into the London virtual cluster.

```bash
docker compose exec kafka-client \
 curl \
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/london/topics/existingSharedTopic \
    --user admin:conduktor \
    --header 'Content-Type: application/json' \
    --data-raw '{ 
        "physicalTopicName": "existingSharedTopic",
        "readOnly": false,
        "concentrated": false
        }'
```

and finally to add the mapping `existingSharedTopic` also into the Paris virtual cluster.

```bash
docker compose exec kafka-client \
 curl \
    --user admin:conduktor \
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/paris/topics/existingSharedTopic \
    --header 'Content-Type: application/json' \
    --data-raw '{ 
        "physicalTopicName": "existingSharedTopic",
        "readOnly": false,
        "concentrated": false
        }'
```

### Step 9: List the topics from the different virtual clusters

List `london` virtual cluster topics

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/london.properties \
    --list
```
List `paris` virtual cluster topics

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/paris.properties \
    --list
```

You should see that the Paris tenant can only see `existingSharedTopic` whereas London can see `existingSharedTopic` and `existingLondonTopic` 
(as well as our previously created topics earlier in the demo).

### Step 10: Consume from the topics

Let's consume the underlying `existingLondonTopic` from the `london` virtual cluster 

```bash
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/london.properties \
    --topic existingLondonTopic \
    --from-beginning \
    --max-messages 1
```

Let's consume the underlying `existingSharedTopic` from the `london` virtual cluster

```bash
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/london.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --max-messages 1
```

Let's consume the underlying `existingSharedTopic` from the `paris` virtual cluster

```bash
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/paris.properties \
    --topic existingSharedTopic \
    --from-beginning \
    --max-messages 1
```

On `existingSharedTopic` the same messages are available to both vclusters.

### Step 11: Visualise what we've been doing

A lot of what we demo'd you've had to use your CLI but checking out the changes can also be done visually with tools such as [Conduktor Console](https://www.conduktor.io/).

We won't demo all the steps of Console today but show a quick view on what we have done and how quickly it could be done visually.

#### Step 12: View the clusters

From what we did today you can see our 3 clusters as below:

![clusters](images/clusters.png "Clusters")

We can create topics with a click of `Create Topic`.

![create a topic](images/create_topic.png "Create Topic")

Creating a topic in our virtual cluster `London` named `londonTopic` and one in `Paris` named `parisTopic`.

Switching back and forth between the `London` and `Paris` clusters and you would see that they only show the topics relevant to their clusters.

We produced some messages to the newly created topics.

![produce to a topic](images/produce1.png "Produce")

Now we select a Value format of `String` and click `Generate Once` to create a a sample message. Clicking `Produce` will produce the message to the cluster.

![produce to a topic](images/produce2.png "Produce")

To consume messages, select the `Consume` tab in Conduktor Platform

![consume from a topic](images/consume.png "Consume").

# Conclusion

Today we ran through the idea of multi-tenany to create virtual clusters available for clients without the cost and time of needing additional backing Kafka clusters.
We looked at how these are isolated, how to set them up from new and how they're compatible mapping to existing topics.

To hear more about how multi-tenancy can work for you [get in touch](https://www.conduktor.io/contact/sales/), we'd love to hear from you!
