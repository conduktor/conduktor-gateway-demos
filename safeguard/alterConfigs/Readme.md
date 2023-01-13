# Alter configs Safeguard

In this demo, we will impose limits on topic configuration changes to ensure that any configuration changed in the cluster adhere to the configured specification.

### Video

[![asciicast](https://asciinema.org/a/R0l3JdxkDjt5GelG92gn70etJ.svg)](https://asciinema.org/a/R0l3JdxkDjt5GelG92gn70etJ)

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Proxy container
* A Conduktor Platform container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Review the platform configuration

`platform-config.yaml` defines 2 clusters:

* Backing Kafka - this is a direct connection to the underlying Kafka cluster hosting the demo
* Proxy - a connection through Conduktor Proxy to the underlying Kafka

Note: Proxy and backing Kafka can use different security schemes. 
In this case the backing Kafka is PLAINTEXT but the proxy is SASL_PLAIN.

### Step 3: Start the environment

Start the environment with

```bash
# setup environment
docker-compose up -d zookeeper kafka1 kafka2 conduktor-proxy kafka-client
```

### Step 4: Create a topic

We create topics using the Kafka console tools, the below creates a topic named `safeguard_topic`

```bash
# Create a topic
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic safeguard_topic
```

List the created topic

```bash
# Check it has been created
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --list
```

### Step 4: Configure safeguard

Conduktor Proxy provides a REST API used to configure the safeguard feature.

```bash
# Configure safeguard
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/feature/guard-alter-configs" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
            "minRetentionMs": 10,
            "maxRetentionMs": 100,
            "minRetentionBytes": 10,
            "maxRetentionBytes": 100,
            "minSegmentMs": 10,
            "maxSegmentMs": 100,
            "minSegmentBytes": 10,
            "maxSegmentBytes": 100,
            "minSegmentJitterMs": 10,
            "maxSegmentJitterMs": 100,
            "minLogRetentionBytes": 10,
            "maxLogRetentionBytes": 100,
            "minLogRetentionMs": 10,
            "maxLogRetentionMs": 100,
            "minLogSegmentBytes": 10,
            "maxLogSegmentBytes": 100
        },
        "direction": "REQUEST",
        "apiKeys": "ALTER_CONFIGS"
    }'
```

### Step 5: Attempt to alter config

Next we try to alter configs of safeguard_topic with a specification that does not match the above.

```bash
# Now, alter topic with invalid configs
docker-compose exec kafka-client kafka-configs \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --alter --topic safeguard_topic \
    --add-config retention.ms=10000,retention.bytes=10000,segment.bytes=10000
```

You should see an output similar to the following:

```bash
Error while executing config command with args '--bootstrap-server conduktor-proxy:6969 --command-config /clientConfig/proxy.properties --alter --topic test --add-config retention.ms=10000,retention.bytes=10000,segment.bytes=10000'
java.util.concurrent.ExecutionException: org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. retention.ms is '10000', must not be greater than 100. segment.bytes is '10000', must not be greater than 100. retention.bytes is '10000', must not be greater than 100
```
### Step 6: Alter valid config

If we modify our command to meet the criteria the configuration is altered.

```bash
# alter topic with valid configs
docker-compose exec kafka-client kafka-configs \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --alter \
    --alter --topic safeguard_topic \
    --add-config retention.ms=50,retention.bytes=50,segment.bytes=50
```

```bash
# check configs has altered
docker-compose exec kafka-client kafka-configs \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --describe \
    --topic safeguard_topic
```

You should see an output similar to the following:
```bash
segment.bytes=50 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:segment.bytes=50, DEFAULT_CONFIG:log.segment.bytes=1073741824}
retention.ms=50 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.ms=50}
retention.bytes=50 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.bytes=50, DEFAULT_CONFIG:log.retention.bytes=-1}
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

### Step 8: View the clusters in Conduktor Platform

From Conduktor Platform navigate to Admin -> Clusters, you should see 2 clusters as below:

![clusters](images/clusters.png "Clusters")

### Step 9: View topic configurations with Conduktor Platform

Navigate to `Console` and select the `Proxy` cluster from the top right.
You should now see the safeguard_topic topic and clicking on it and select `Configuration` tab.

You should see an output similar to the following:

![alter configs safeguard topic](images/alter_configs_safeguard.png "Alter configs safeguard")
