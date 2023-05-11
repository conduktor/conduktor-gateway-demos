# Conduktor Gateway Multi Tenant Demo

## What is Multi Tenancy?

Conduktor Gateway's multi tenancy feature allows 1 Kafka cluster to appear as a number of isolated clusters to clients. Each cluster/tenant can be operated upon separately with no concern of side effects for other clusters.

### Architecture diagram
![architecture diagram](images/multi-tenant.png "multi tenant")

### Video

[![asciicast](https://asciinema.org/a/PncSYV3jST1cdlhla9JGGAVHy.svg)](https://asciinema.org/a/PncSYV3jST1cdlhla9JGGAVHy)

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Gateway container
* A Conduktor Platform container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Review the platform configuration

`platform-config.yaml` defines 3 clusters:

* Backing Kafka - this is a direct connection to the underlying Kafka cluster hosting the demo
* London - a connection through Conduktor Gateway that represents the London tenant
* Paris - a connection through Conduktor Gateway that represents the Paris tenant

Note: Tenancy is determined by the SASL credentials configured for each cluster. These credentials provide a token that encodes tenancy information.

### Step 3: Start the environment

Start the environment with

```bash
docker-compose up -d zookeeper kafka1 kafka2 kafka-client
sleep 10
docker-compose up -d conduktor-proxy
sleep 5
echo "Environment started"
```

### Step 4: Create topics

We create topics using the Kafka console tools, the below creates a topic name `londonTopic` in cluster `London` and `parisTopic` in cluster `Paris`

```bash
docker-compose exec kafka-client kafka-topics --bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/london.properties --create --topic londonTopic
docker-compose exec kafka-client kafka-topics --bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/paris.properties --create --topic parisTopic
```

List all topics from both clusters to see that, although they are hosted on the same underlying cluster, the topics are isolated from eachother:

```bash
docker-compose exec kafka-client kafka-topics --bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/london.properties --list
docker-compose exec kafka-client kafka-topics --bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/paris.properties --list
```

### Step 5: Produce data to the topics

You can produce with the console tools as follows:

```bash
echo testMessageLondon | docker-compose exec -T kafka-client kafka-console-producer --bootstrap-server conduktor-proxy:6969 --producer.config /clientConfig/london.properties --topic londonTopic
echo testMessageParis | docker-compose exec -T kafka-client kafka-console-producer --bootstrap-server conduktor-proxy:6969 --producer.config /clientConfig/paris.properties --topic parisTopic
```

### Step 6: Consume from the topics

And consume the messages produced above. Note that the message `testMessageLondon` will never be consumed by a `Paris` cluster client due to cluster isolation. 

```bash
docker-compose exec kafka-client kafka-console-consumer --bootstrap-server conduktor-proxy:6969 --consumer.config /clientConfig/london.properties --topic londonTopic --from-beginning
docker-compose exec kafka-client kafka-console-consumer --bootstrap-server conduktor-proxy:6969 --consumer.config /clientConfig/paris.properties --topic parisTopic --from-beginning
```

### Step 7: Applying Multi Tenancy to existing topics

During migration to Conduktor Gateway you may want to make up a tenant population from existing topics in your Kafka cluster. Conduktor Gateway allows this via administration APIs. In this next section we will create topics on the backing Kafka cluster and add them to tenants within Conduktor Gateway

Let's start by creating some pre-exiting topics and adding data

```bash
docker-compose exec kafka-client kafka-topics --bootstrap-server kafka1:9092 --create --topic existingLondonTopic
docker-compose exec kafka-client kafka-topics --bootstrap-server kafka1:9092 --create --topic existingSharedTopic
echo existingLondonMessage | docker-compose exec -T kafka-client kafka-console-producer --bootstrap-server kafka1:9092 --topic existingLondonTopic
echo existingSharedMessage | docker-compose exec -T kafka-client kafka-console-producer --bootstrap-server kafka1:9092 --topic existingSharedTopic
```

### Step 8: Configuring tenants for existing topics

We'll create the following mappings:
* tenant: `London` can see `existingLondonTopic` and `existingSharedTopic`
* tenant: `Paris` can see only `existingSharedTopic`

First we create a topic mapping for each topic. These map a topic name for the tenant (`existingLondonTopic`/`existingSharedTopic` url param ) to a topic name in the Kafka cluster (`topicName` in the request body). These names do not have to match but they match here for clarity.

```bash
docker-compose exec kafka-client curl -u superUser:superUser -vvv -X POST conduktor-proxy:8888/topicMappings/london/existingLondonTopic -d '{ "topicName":"existingLondonTopic" }'
docker-compose exec kafka-client curl -u superUser:superUser -vvv -X POST conduktor-proxy:8888/topicMappings/london/existingSharedTopic -d '{ "topicName":"existingSharedTopic" }'
docker-compose exec kafka-client curl -u superUser:superUser -vvv -X POST conduktor-proxy:8888/topicMappings/paris/existingSharedTopic -d '{ "topicName":"existingSharedTopic" }'
```

Next we must add the topics to each tenant.

```bash
docker-compose exec kafka-client curl -u superUser:superUser -vvv -X POST conduktor-proxy:8888/topics/london -d '{ "name":"existingLondonTopic" }'
docker-compose exec kafka-client curl -u superUser:superUser -vvv -X POST conduktor-proxy:8888/topics/london -d '{ "name":"existingSharedTopic" }'
docker-compose exec kafka-client curl -u superUser:superUser -vvv -X POST conduktor-proxy:8888/topics/paris -d '{ "name":"existingSharedTopic" }' 
```

Note: the url params `london`/`paris` represent the London/Paris tenants in these APIs. 

### Step 9: List topics as the different tenants

```bash
docker-compose exec kafka-client kafka-topics --bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/london.properties --list
docker-compose exec kafka-client kafka-topics --bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/paris.properties --list
```

You should see that the Paris tenant can only see `existingSharedTopic` whereas London can see `existingSharedTopic` and `existingLondonTopic` 

### Step 10: Consume from the topics

```bash
docker-compose exec kafka-client kafka-console-consumer --bootstrap-server conduktor-proxy:6969 --consumer.config /clientConfig/london.properties --topic existingLondonTopic --from-beginning
docker-compose exec kafka-client kafka-console-consumer --bootstrap-server conduktor-proxy:6969 --consumer.config /clientConfig/london.properties --topic existingSharedTopic --from-beginning
docker-compose exec kafka-client kafka-console-consumer --bootstrap-server conduktor-proxy:6969 --consumer.config /clientConfig/paris.properties --topic existingSharedTopic --from-beginning
```

On `existingSharedTopic` the same messages are available to both tenants.


### Step 11: Log into the platform

> The remaining steps in this demo require a Conduktor Platform license. For more information on this [Arrange a technical demo](https://www.conduktor.io/contact/demo)

Once you have a license key, place it in `platform-config.yaml` under the key: `license` e.g.:

```yaml
license: "eyJhbGciOiJFUzI1NiIsInR5cCI6I..."
```

the start the Conduktor Platform container:

```bash
docker-compose up -d conduktor-platform
```

From a browser, navigate to `http://localhost:8080` and use the following to log in (as specified in `platform-config.yaml`):

Username: bob@conduktor.io
Password: admin

### Step 12: View the clusters

From Conduktor Platform navigate to Admin -> Clusters, you should see 3 clusters as below:

![clusters](images/clusters.png "Clusters")

### Step 13: Create Topics with Conduktor Platform

To create topics through Conduktor Platform, navigate to `Console`, select the correct cluster from the top right, and click `Create Topic`

![create a topic](images/create_topic.png "Create Topic")

Create a topic in cluster `London` named `londonTopic` and one in `Paris` named `parisTopic`

Switch back and forth between the `London` and `Paris` clusters and you will see that they only show the topics relevant to their clusters. 

### Step 14: Produce with Conduktor Platform

Let's produce some messages to the newly created topics. Go to `Console`, click on the topic you want to produce to, and select the produce tab.

![produce to a topic](images/produce1.png "Produce")

Now we select a Value format of `String` and click `Generate Once` to create a a sample message. Clicking `Produce` will produce the message to the cluster.

![produce to a topic](images/produce2.png "Produce")

### Step 15: Consumer with Conduktor Platform

To view produced messages, select the `Consume` tab in Conduktor Platform

![consume from a topic](images/consume.png "Consume")
