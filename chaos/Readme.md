# Conduktor Proxy Chaos Demo

## What is Conduktor Proxy Chaos?

Chaos testing is the process of testing a distributed computing system to ensure that it can withstand unexpected disruptions. Kafka is an extremely resilient system and so it can be difficult to injects disruptions in order to be sure that applications can handle them.

Conduktor Proxy comes to the rescue, simulating common Kafka disruptions without and actual disruption occurring in the underlying Kafka cluster. 

In this demo we will inject the following disruptions with Conduktor Proxy and observe the result:

* Broken Broker - Inject intermittent errors in client connections to brokers
* Duplication - Simulate request duplication
* Leader Election - Simulate leader elections on the underlying Kafka cluster
* Random Bytes - Add random bytes to message data
* Slow Broker - Introduce intermittent latency in broker communication
* Slow Topic - Introduce latency for specific topics
* Invalid Schema Id - Simulate broker responses as if the schema provided in a message was invalid.

## Running the demo: Setup

### Step 1: review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Proxy container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: start the environment

Start the environment with

```bash
docker-compose up -d
```

### Step 3: Create topics

We create topics using the Kafka console tools, the below creates a topic named `conduktor_topic`

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic conduktor_topic
```

List the created topic

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --list
```

## Running the demo: Injecting Chaos

Conduktor-Proxy provides a number of different ways to inject Chaos into your data flows:

* [Broken Broker](#brokenBroker)
* [Duplicate Writes](#duplicateWrites)
* [Leader Election](#leaderElection)
* [Random Bytes Injections](#randomBytes)
* [Slow Broker](#slowBroker)
* [Slow Topic](#slowTopic)
* [Invalid Schema Id Injection](#invalidSchema)

### <a name="brokenBroker"></a> Step 4: Broken Broker

Conduktor Proxy exposes a REST API to configure the chaos features.

The command below will instruct Conduktor Proxy to inject failures for some Produce requests that are consistent with broker side issues. 

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/broken-broker" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": {
	        "brokerIds": [],
	        "duration": 6000,
	        "durationUnit": "MILLISECONDS",
	        "quietPeriod": 20000,
	        "quietPeriodUnit": "MILLISECONDS",
	        "minLatencyToAddInMilliseconds": 6000,
	        "maxLatencyToAddInMilliseconds": 7000,
	        "errors": ["REQUEST_TIMED_OUT", "BROKER_NOT_AVAILABLE", "OFFSET_OUT_OF_RANGE", "NOT_ENOUGH_REPLICAS", "INVALID_REQUIRED_ACKS"]
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```
### Step 5 Inject some chaos

Let's produce some records to our created topic and observe some errors being injected by Conduktor Proxy.

```bash
docker-compose exec kafka-client kafka-producer-perf-test \
  --producer.config /clientConfig/proxy.properties \
  --record-size 100 \
  --throughput 10 \
  --num-records 100 \
  --topic conduktor_topic
```

This should produce output similar to this:

```bash
[2022-11-16 17:00:42,193] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 5 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: NOT_ENOUGH_REPLICAS (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-16 17:00:42,474] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 6 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: NOT_ENOUGH_REPLICAS (org.apache.kafka.clients.producer.internals.Sender)
6 records sent, 0.8 records/sec (0.00 MB/sec), 1198.5 ms avg latency, 6632.0 ms max latency.
org.apache.kafka.common.errors.InvalidRequiredAcksException: Produce request specified an invalid value for required acks.
[2022-11-16 17:00:42,491] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 8 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: NOT_ENOUGH_REPLICAS (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-16 17:00:42,492] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 9 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: NOT_ENOUGH_REPLICAS (org.apache.kafka.clients.producer.internals.Sender)
100 records sent, 9.999000 records/sec (0.00 MB/sec), 2454.80 ms avg latency, 6852.00 ms max latency, 2046 ms 50th, 6560 ms 95th, 6852 ms 99th, 6852 ms 99.9th.
```

Note the `NOT_ENOUGH_REPLICAS` errors.

### Step 6: Reset

To stop chaos injection run the below:

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request DELETE "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/broken-broker/apiKeys/PRODUCE/direction/REQUEST"
```

### Step 7: Run with no Chaos

To verify, let's run the produce test again to confirm there are no errors

```bash
docker-compose exec kafka-client kafka-producer-perf-test \
  --producer.config /clientConfig/proxy.properties \
  --record-size 100 \
  --throughput 10 \
  --num-records 100 \
  --topic conduktor_topic
```

This should produce output similar to the following:

```bash
52 records sent, 10.3 records/sec (0.00 MB/sec), 16.0 ms avg latency, 388.0 ms max latency.
100 records sent, 10.001000 records/sec (0.00 MB/sec), 10.69 ms avg latency, 388.00 ms max latency, 5 ms 50th, 43 ms 95th, 388 ms 99th, 388 ms 99.9th.
```

### <a name="duplicateWrites"></a> Step 8: Duplicate Writes

Conduktor Proxy exposes a REST API to configure the chaos features.

The command below will instruct Conduktor Proxy to inject duplicate records on produce requests.

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic conduktor_topic_duplicate
```

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/duplicate-resource" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
          "topics": ["conduktor_topic_duplicate"], 
          "duration": 1, 
          "rateInPercent": 100, 
          "quietPeriod": 1, 
          "timeUnit": "MINUTES" 
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```
### Step 9: Inject some chaos

Let's produce some records to our created topic.

```bash
docker-compose exec kafka-client kafka-producer-perf-test \
  --producer.config /clientConfig/proxy.properties \
  --record-size 100 \
  --throughput 10 \
  --num-records 10 \
  --topic conduktor_topic_duplicate
```

And see the duplicated records:

```bash
docker-compose exec kafka-client kafka-console-consumer \
  --bootstrap-server conduktor-proxy:6969 \
  --consumer.config /clientConfig/proxy.properties \
  --from-beginning \
  --topic conduktor_topic_duplicate
```

This should produce output similar to this:

```bash
CGJROBQTGLLMKEHLHFUVFZNXYLKVFCAZSWKKHXYLRJJRUZHSKJNAFEHNINWWKGWTMCQSIFNFNXREAHPKKHNEJLEMVSNTDGBNCZPJ
OOJXKRJIVPUYNYFHBUTAPJHBTNHNKLYTIMMPKMSBHRPNZHHMMJQFCLDFZUFLYHEPRJEBHJLOXJOZSJHWOKZGZLKWJANKCUZRMUMM
NRWCNDBIYEHZQRRNSDASJMXJAZVHGDIUPDXSGRNWDPVMXPYUCWGGCKOCWVXCGWSPZQLWLWKQDBDWUAKKVLITEVTSIWSHDZTEMYNH
SSXVNJHPDQDXVCRASTVYBCWVMGNYKRXVZXKGXTSPSJDGYLUEGQFLAQLOCFLJBEPOWFNSOMYARHAOPUFOJHHDXEHXJBHWGSMZJGNL
SSXVNJHPDQDXVCRASTVYBCWVMGNYKRXVZXKGXTSPSJDGYLUEGQFLAQLOCFLJBEPOWFNSOMYARHAOPUFOJHHDXEHXJBHWGSMZJGNL
ONJVXZXZOZITKXJBOZWDJMCBOSYQQKCPRRDCZWMRLFXBLGQPRPGRNTAQOOSVXPKJPJLAVSQCCRXFRROLLHWHOHFGCFWPNDLMWCSS
ONJVXZXZOZITKXJBOZWDJMCBOSYQQKCPRRDCZWMRLFXBLGQPRPGRNTAQOOSVXPKJPJLAVSQCCRXFRROLLHWHOHFGCFWPNDLMWCSS
```

Note the duplicated messages.

### Step 10: Reset

To stop chaos injection run the below:

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request DELETE "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/duplicate-resource/apiKeys/PRODUCE/direction/REQUEST"
```

### <a name="leaderElection"></a> Step 11: Leader Election

Conduktor Proxy exposes a REST API to configure the chaos features.

The command below will instruct Conduktor Proxy to simulate a leader election on partitions being produced to through Conduktor Proxy.

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/leader-election" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": {
          "rateInPercent": 100,
          "duration":6000, 
          "quietPeriod":20000,
          "timeUnit":"MILLISECONDS",
          "errors":["LEADER_NOT_AVAILABLE","NOT_LEADER_OR_FOLLOWER","BROKER_NOT_AVAILABLE"]
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```
### Step 12: Inject some chaos

Let's produce some records to our created topic.

```bash
docker-compose exec kafka-client kafka-producer-perf-test \
  --producer.config /clientConfig/proxy.properties \
  --record-size 100 \
  --throughput 10 \
  --num-records 10 \
  --topic conduktor_topic
```

This should produce output similar to this:

```bash
[2022-11-17 14:15:18,481] WARN [Producer clientId=perf-producer-client] Received invalid metadata error in produce request on partition conduktor_topic-0 due to org.apache.kafka.common.errors.NotLeaderOrFollowerException: For requests intended only for the leader, this error indicates that the broker is not the current leader. For requests intended for any replica, this error indicates that the broker is not a replica of the topic partition.. Going to request metadata update now (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 14:15:18,584] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 121 on topic-partition conduktor_topic-0, retrying (2147483588 attempts left). Error: NOT_LEADER_OR_FOLLOWER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 14:15:18,584] WARN [Producer clientId=perf-producer-client] Received invalid metadata error in produce request on partition conduktor_topic-0 due to org.apache.kafka.common.errors.NotLeaderOrFollowerException: For requests intended only for the leader, this error indicates that the broker is not the current leader. For requests intended for any replica, this error indicates that the broker is not a replica of the topic partition.. Going to request metadata update now (org.apache.kafka.clients.producer.internals.Sender)
1 records sent, 0.2 records/sec (0.00 MB/sec), 6511.0 ms avg latency, 6511.0 ms max latency.
10 records sent, 1.531159 records/sec (0.00 MB/sec), 6010.20 ms avg latency, 6511.00 ms max latency, 6118 ms 50th, 6511 ms 95th, 6511 ms 99th, 6511 ms 99.9th.
```

Note the exceptions indicating that the current leader has changed.

### Step 13: Reset

To stop chaos injection run the below:

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request DELETE "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/leader-election/apiKeys/PRODUCE/direction/REQUEST"
```

### <a name="randomBytes"></a> Step 14: Random Bytes

First let's create a topic to operate on.

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic conduktor_topic_random
```

Conduktor Proxy exposes a REST API to configure the chaos features.

The command below will instruct Conduktor Proxy to append random bytes to messages produced.

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/random-bytes" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
          "topics": ["conduktor_topic_random"], 
          "nbMessages": 1, 
          "sizeInBytes": 10 
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```
### Step 15: Inject some chaos

Let's produce some records to our created topic.

```bash
docker-compose exec kafka-client kafka-producer-perf-test \
  --producer.config /clientConfig/proxy.properties \
  --record-size 100 \
  --throughput 10 \
  --num-records 10 \
  --topic conduktor_topic_random
```

And see the appended bytes in the records:

```bash
docker-compose exec kafka-client kafka-console-consumer \
  --bootstrap-server conduktor-proxy:6969 \
  --consumer.config /clientConfig/proxy.properties \
  --from-beginning \
  --topic conduktor_topic_random
```

This should produce output similar to this:

```bash
TGTIFVEQPSYBDXEXORPQDDODZGBELOISTRWXMEYWVVHGMJKWLJCCHPKAFRASZEYQZCVLFSLOWTLBMPPWPPFPQSAZPTULSTCDMODY
KZGSRFQTRFTGCNMNXQQIYVUQZHVNIPHZWVBSGOBYIFDNNXUTBBQUYNXOZCSICGRTZSSRHROJRGBHMHEQJRDLOQBEPTOBMYLMIGPP
DPOLTEUVDGATCGYPQOGOYYESKEGBLOCBIYSLQEYGCCIPBXPNSPKDYTBEWDHBHWVDPLOVHJPNYGJUHKKHDASNFGZDAIWWQEPPBRJK
SSXVNJHPDQDXVCRASTVYBCWVMGNYKRXVZXKGXTSPSJDGYLUEGQFLAQLOCFLJBEPOWFNSOMYARHAOPUFOJHHDXEHXJBHWGSMZJGNLH|��>�yC
ONJVXZXZOZITKXJBOZWDJMCBOSYQQKCPRRDCZWMRLFXBLGQPRPGRNTAQOOSVXPKJPJLAVSQCCRXFRROLLHWHOHFGCFWPNDLMWCSSv��k�z�
HWXQQYKALAAWCMXYLMZALGDESKKTEESEMPRHROVKUMPSXHELIDQEOOHOIHEGJOAZBVPUMCHSHGXZYXXQRUICRIJGQEBBWAXABQRI�����W�N
RUGZJUUVFYQOVCDEDXYFPRLGSGZXSNIAVODTJKSQWHNWVPSAMZKOUDTWHIORJSCZIQYPCZMBYWKDIKOKYNGWPXZWMKRDCMBXKFUI��*2�Ћ�
LWDHBFXRFAOPRUGDFLPDLHXXCXCUPLWGDPPHEMJGMTVMFQQFVCUPOFYWLDUEBICKPZKHKVMCJVWVKTXBKAPWAPENUEZNWNWDCACD	�'6�x���
```

Note the longer messages with extra bytes

### Step 16: Reset

To stop chaos injection run the below:

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request DELETE "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/random-bytes/apiKeys/PRODUCE/direction/REQUEST"
```

### <a name="slowBroker"></a> Step 17: Slow Broker

Conduktor Proxy exposes a REST API to configure the chaos features.

The command below will instruct Conduktor Proxy to simulate slow responses from brokers.

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/slow-broker" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": {
          "brokerIds":[],
          "duration":6000,
          "durationUnit":"MILLISECONDS",
          "quietPeriod":20000,
          "quietPeriodUnit":"MILLISECONDS",
          "minLatencyToAddInMilliseconds":6000,
          "maxLatencyToAddInMilliseconds":7000
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```
### Step 18: Inject some chaos

Let's produce some records to our created topic.

```bash
docker-compose exec kafka-client kafka-producer-perf-test \
  --producer.config /clientConfig/proxy.properties \
  --record-size 100 \
  --throughput 10 \
  --num-records 10 \
  --topic conduktor_topic
```

This should produce output similar to this:

```bash
1 records sent, 0.1 records/sec (0.00 MB/sec), 7357.0 ms avg latency, 7357.0 ms max latency.
[2022-11-17 15:21:28,803] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 5 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:21:28,805] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 6 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:21:28,805] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 7 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:21:29,062] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 8 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
10 records sent, 1.292825 records/sec (0.00 MB/sec), 7019.40 ms avg latency, 7357.00 ms max latency, 6990 ms 50th, 7357 ms 95th, 7357 ms 99th, 7357 ms 99.9th.
```

Note the very high latency numbers indicating slow responses.

### Step 19: Reset

To stop chaos injection run the below:

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request DELETE "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/slow-broker/apiKeys/PRODUCE/direction/REQUEST"
```

### <a name="slowTopic"></a> Step 20: Slow Topic

Conduktor Proxy exposes a REST API to configure the chaos features.

The command below will instruct Conduktor Proxy to simulate slow responses from the brokers. It differs from the above in that it will operate only on a set of topics rather than all traffic.

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic conduktor_topic_slow
```

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/slow-topic" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": {
          "topicPatterns":["conduktor_topic_slow"],
          "duration":6000,
          "durationUnit":"MILLISECONDS",
          "quietPeriod":20000,
          "quietPeriodUnit":"MILLISECONDS",
          "minLatencyToAddInMilliseconds":6000,
          "maxLatencyToAddInMilliseconds":7000
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```
### Step 21: Inject some chaos

Let's produce some records to our created topic.

```bash
docker-compose exec kafka-client kafka-producer-perf-test \
  --producer.config /clientConfig/proxy.properties \
  --record-size 100 \
  --throughput 10 \
  --num-records 10 \
  --topic conduktor_topic_slow
```

This should produce output similar to this:

```bash
1 records sent, 0.1 records/sec (0.00 MB/sec), 7251.0 ms avg latency, 7251.0 ms max latency.
[2022-11-17 15:26:32,507] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 5 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:26:32,510] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 6 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:26:32,510] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 7 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
[2022-11-17 15:26:32,511] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 8 on topic-partition conduktor_topic-0, retrying (2147483646 attempts left). Error: OUT_OF_ORDER_SEQUENCE_NUMBER (org.apache.kafka.clients.producer.internals.Sender)
10 records sent, 1.354463 records/sec (0.00 MB/sec), 6830.00 ms avg latency, 7251.00 ms max latency, 6900 ms 50th, 7251 ms 95th, 7251 ms 99th, 7251 ms 99.9th.
```

Note the very high latency numbers indicating slow responses.

### Step 22: Reset

To stop chaos injection run the below:

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request DELETE "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/slow-topic/apiKeys/PRODUCE/direction/REQUEST"
```

### <a name="invalidSchema"></a> Step 23: Invalid Schema

Conduktor Proxy exposes a REST API to configure the chaos features.

The command below will instruct Conduktor Proxy to inject Schema Ids into messages. This simulates a situation where clients cannot deserialize messages with the schema information provided.

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic conduktor_topic_schema
```

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "tenant": "1-1",
        "topic": "conduktor_topic_schema",
        "messageFormat": "JSON"
    }'
```

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/invalid-schema" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
          "topics": ["conduktor_topic_schema"], 
          "fakeSchemaId": 999 
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```
### Step 24: Inject some chaos

Let's produce a record to our created topic.

```bash
docker-compose exec schema-registry bash -c "cat /clientConfig/payload.json | kafka-json-schema-console-producer \
    --bootstrap-server conduktor-proxy:6969 \
    --topic conduktor_topic_schema  \
    --producer.config /clientConfig/proxy.properties \
    --property value.schema='{ 
        \"title\": \"someSchema\", 
        \"type\": \"object\", 
        \"properties\": { 
          \"some-valid\": { 
            \"type\": \"string\" 
          }
        }
      }'"
```

And consume them with a schema aware consumer.

```bash
docker-compose exec schema-registry kafka-json-schema-console-consumer \
    --bootstrap-server conduktor-proxy:6969 \
    --topic conduktor_topic_schema \
    --consumer.config /clientConfig/proxy.properties \
    --from-beginning 
```

This should produce output similar to this:

```bash
Processed a total of 1 messages
[2022-11-17 15:59:13,184] ERROR Unknown error when running consumer:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.SerializationException: Error retrieving JSON schema for id 999
	at io.confluent.kafka.serializers.AbstractKafkaSchemaSerDe.toKafkaException(AbstractKafkaSchemaSerDe.java:259)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:182)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:130)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter$JsonSchemaMessageDeserializer.deserialize(JsonSchemaMessageFormatter.java:103)
	at io.confluent.kafka.formatter.json.JsonSchemaMessageFormatter.writeTo(JsonSchemaMessageFormatter.java:94)
	at io.confluent.kafka.formatter.SchemaMessageFormatter.writeTo(SchemaMessageFormatter.java:181)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:116)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:76)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:53)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Caused by: io.confluent.kafka.schemaregistry.client.rest.exceptions.RestClientException: Schema 999 not found; error code: 40403
	at io.confluent.kafka.schemaregistry.client.rest.RestService.sendHttpRequest(RestService.java:301)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.httpRequest(RestService.java:371)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.getId(RestService.java:840)
	at io.confluent.kafka.schemaregistry.client.rest.RestService.getId(RestService.java:813)
	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.getSchemaByIdFromRegistry(CachedSchemaRegistryClient.java:294)
	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.getSchemaBySubjectAndId(CachedSchemaRegistryClient.java:417)
	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaDeserializer.deserialize(AbstractKafkaJsonSchemaDeserializer.java:119)
	... 8 more

```

### Step 25: Reset

To stop chaos injection run the below:

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request DELETE "conduktor-proxy:8888/tenant/1-1/user/test@conduktor.io/feature/invalid-schema/apiKeys/PRODUCE/direction/REQUEST"
```







