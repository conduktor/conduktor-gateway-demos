# Conduktor Proxy Multi Tenant Demo

## What is Multi Tenancy?

Conduktor Proxy's multi tenancy feature allows 1 Kafka cluster to appear as a number of isolated clusters to clients. Each cluster/tenant can be operated upon separately with no concern of side effects for other clusters.

## Running the demo

### Step 1: review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Proxy container
* A Conduktor Platform container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: review the platform configuration

`platform-config.yaml` defines 3 clusters:

* Backing Kafka - this is a direct connection to the underlying Kafka cluster hosting the demo
* London - a connection through Conduktor Proxy that represents the London tenant
* Paris - a connection through Conduktor Proxy that represents the Paris tenant

Note: Tenancy is determined by the SASL credentials configured for each cluster. These credentials provide a token that encodes tenancy information.

### Step 3: start the environment

Start the environment with

```bash
docker-compose up -d zookeeper kafka1 kafka2 conduktor-proxy kafka-client
```

### Step 4: Create topics

We create topics using the Kafka console tools, the below creates a topic name `london_topic` in cluster `London` and `paris_topic` in cluster `Paris`

```bash
docker-compose exec kafka-client kafka-topics --bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/london.properties --create --topic london_topic
docker-compose exec kafka-client kafka-topics --bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/paris.properties --create --topic paris_topic
```

List all topics from both clusters to see that, although they are hosted on the same underlying cluster, the topics are isolated from eachother:

```bash
docker-compose exec kafka-client kafka-topics --bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/london.properties --list
docker-compose exec kafka-client kafka-topics --bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/paris.properties --list
```

### Step 5: Produce data to the topics

You can produce with the console tools as follows:

```bash
echo testMessageLondon | docker-compose exec -T kafka-client kafka-console-producer --bootstrap-server conduktor-proxy:6969 --producer.config /clientConfig/london.properties --topic london_topic
echo testMessageParis | docker-compose exec -T kafka-client kafka-console-producer --bootstrap-server conduktor-proxy:6969 --producer.config /clientConfig/paris.properties --topic paris_topic
```

### Step 6: Consume from the topics

And consume the messages produced above. Note that the message `testMessageLondon` will never be consumed by a `Paris` cluster client due to cluster isolation. 

```bash
docker-compose exec kafka-client kafka-console-consumer --bootstrap-server conduktor-proxy:6969 --consumer.config /clientConfig/london.properties --topic london_topic --from-beginning
docker-compose exec kafka-client kafka-console-consumer --bootstrap-server conduktor-proxy:6969 --consumer.config /clientConfig/paris.properties --topic paris_topic --from-beginning
```

### Step 7: Log into the platform

> The remaining steps in this demo require a Conduktor Platform license. For more information on this [Arrange a technical demo](https://www.conduktor.io/contact/demo)

Once you have a license key, place it in `platform-config.yaml` under the key: `lincense` e.g.:

```yaml
auth:
  demo-users:
    - email: "test@conduktor.io"
      password: "password1"
      groups:
        - ADMIN
license: "eyJhbGciOiJFUzI1NiIsInR5cCI6I..."
```

the start the Conduktor Platform container:

```bash
docker-compose up -d conduktor-platform
```

From a browser, navigate to `http://localhost:8080` and use the following to log in:

Username: test@conduktor.io
Password: password1

### Step 5: View the clusters

From Conduktor Platform navigate to Admin -> Clusters, you should see 3 clusters as below:

![clusters](images/clusters.png "Clusters")

### Step 8: Create Topics with Conduktor Platform

To create topics through Conduktor Platform, navigate to `Console`, select the correct cluster from the top right, and click `Create Topic`

![create a topic](images/create_topic.png "Create Topic")

Create a topic in cluster `London` named `london_topic` and one in `Paris` named `paris_topic`

Switch back and forth between the `London` and `Paris` clusters and you will see that they only show the topics relevant to their clusters. 

### Step 9: Produce with Conduktor Platform

Let's produce some messages to the newly created topics. Go to `Console`, click on the topic you want to produce to, and select the produce tab.

![produce to a topic](images/produce1.png "Produce")

Now we select a Value format of `String` and click `Generate Once` to create a a sample message. Clicking `Produce` will produce the message to the cluster.

![produce to a topic](images/produce2.png "Produce")

### Step 10: Consumer with Conduktor Platform

To view produced messages, select the `Consume` tab in Conduktor Platform

![consume from a topic](images/consume.png "Consume")