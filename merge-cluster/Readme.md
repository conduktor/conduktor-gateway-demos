# Conduktor Proxy Merge Cluster Demo

## What is Conduktor Proxy Merge Cluster?

Conduktor Proxy's merge cluster feature help single kafka clients can work with multiple kafka clusters transparently. 


### Architecture diagram
![architecture diagram](images/merge-cluster.png "merge cluster")


### Video

[![asciicast](https://asciinema.org/a/crmwYEknaA61THMW5mzrd11SI.svg)](https://asciinema.org/a/crmwYEknaA61THMW5mzrd11SI)

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* Two kafka clusters. One cluster has:
  * A single Zookeeper Server
  * A 2 node Kafka cluster
* A single Conduktor Proxy container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Start the environment

Start the environment with

```bash
docker-compose up -d 
```

### Step 4: Create topics
For merge cluster to work, we need topic exist on backing kafka cluster first.
We connect to each kafka cluster and create topics using the Kafka console tools.
The below creates two topics:
* master_topic on master cluster
* secondary_topic on secondary cluster

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1_m:9092 \
    --create --if-not-exists \
    --topic master_topic
```

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1_s1:19092 \
    --create --if-not-exists \
    --topic secondary_topic
```


We need to register topic and cluster id with conduktor-proxy

```bash
docker-compose exec kafka-client curl \
-X POST \
-H "content-type:application/json" \
-H "authorization:Basic bm9uZTpub25l" \
'conduktor-proxy:8888/topicMappings/passThroughTenant/master_topic' \
-d '{ "topicName":"master_topic", "isConcentrated": false, "isCompacted": "false"}'
```

```bash
docker-compose exec kafka-client curl \
--silent \
-H "content-type:application/json" \
-H "authorization:Basic bm9uZTpub25l" \
'conduktor-proxy:8888/topicMappings/passThroughTenant/secondary_topic' \
-d '{ "clusterId" : "cluster1", "topicName":"secondary_topic", "isConcentrated": false, "isCompacted": "false"}'
```

```bash
docker-compose exec kafka-client curl  -H "content-type:application/json" -H "authorization:Basic bm9uZTpub25l" \
'conduktor-proxy:8888/topicMappings/passThroughTenant'
```

```bash
docker-compose exec kafka-client curl \
-X POST \
-H "content-type:application/json" \
-H "authorization:Basic bm9uZTpub25l" \
'conduktor-proxy:8888/topics/passThroughTenant' -d '{"name":"master_topic"}'
```

```bash
docker-compose exec kafka-client curl \
-X POST \
-H "content-type:application/json" \
-H "authorization:Basic bm9uZTpub25l" \
'conduktor-proxy:8888/topics/passThroughTenant' -d '{"name":"secondary_topic"}'
```



### Step 5: Produce data to the topic

Let's produce a simple record to the master_topic topic and secondary_topic topic

```bash
echo 'master_topic_record' | docker-compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server conduktor-proxy:6969 \
        --topic master_topic
```

```bash
echo 'secondary_topic_record' | docker-compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server conduktor-proxy:6969 \
        --topic secondary_topic
```

### Step 6: Consume to verify

Let's consume from proxy.

```bash
docker-compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-proxy:6969 \
    --topic master_topic \
    --from-beginning \
    --max-messages 1 \
    --property print.headers=true
```
You should see the message:
```text
NO_HEADERS	master_topic_record
```

```bash
docker-compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-proxy:6969 \
    --topic secondary_topic \
    --from-beginning \
    --max-messages 1 \
    --property print.headers=true
```
You should see the message:
```text
NO_HEADERS	secondary_topic_record
```

Now, consume from kafka cluster


```bash
docker-compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server kafka1_m:9092 \
    --topic master_topic \
    --from-beginning \
    --max-messages 1 \
    --property print.headers=true
```
You should see the message:
```text
NO_HEADERS	master_topic_record
```

```bash
docker-compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server kafka1_s1:19092 \
    --topic secondary_topic \
    --from-beginning \
    --max-messages 1 \
    --property print.headers=true
```
You should see the message:
```text
NO_HEADERS	secondary_topic_record
```
