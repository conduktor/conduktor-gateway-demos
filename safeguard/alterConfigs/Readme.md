# Alter broker config policy

In this demo, we will impose limits on broker configuration changes to ensure that any configuration changed in the cluster adhere to the configured specification.

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Gateway container
* A Conduktor Console container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Review the Console configuration

The `platform-config.yaml` defines 2 cluster configurations:

* Backing Kafka - this is a direct connection to the underlying Kafka cluster hosting the demo
* Gateway - a connection through Conduktor Gateway to the underlying Kafka

Note: Gateway and the backing Kafka can use different security schemes.
In this case the backing Kafka is PLAINTEXT but the gateway is SASL_PLAIN.

### Step 3: Start the environment

Start the environment with

```bash
docker compose up --wait --detach
```

### Step 4: Create a topic

We create topics using the Kafka console tools, the below creates a topic named `safeguardTopic`

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create --if-not-exists \
    --topic safeguardTopic
```

Check it has been created

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --list
```

### Step 4: Add the interceptor

Conduktor gateway provides a REST API used to add interceptors.

Add alter topic config policy

```bash
docker-compose exec kafka-client \
  curl \
    --user "admin:conduktor" \
    --request POST conduktor-gateway:8888/admin/interceptors/v1/vcluster/someCluster/username/someUsername/interceptor/guard-alter-configs \
    --header "Content-Type: application/json" \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.safeguard.AlterTopicConfigPolicyPlugin",
        "priority": 100,
        "config": {
          "topic": ".*",
          "retentionMs": {
            "min": 86400000,
            "max": 432000000
          }
        }
    }'
```

### Step 5: Attempt to alter config

Next we try to alter configs of safeguardTopic with a specification that does not match the above.

Now, alter topic with invalid configs

```bash
docker compose exec kafka-client \
  kafka-configs \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --alter \
    --topic safeguardTopic \
    --add-config retention.ms=10000
```

You should see an output similar to the following:

```
Error while executing config command with args '--bootstrap-server conduktor-gateway:6969 --command-config /clientConfig/gateway.properties --alter --topic test --add-config retention.ms=10000

Caused by: org.apache.kafka.common.errors.PolicyViolationException: Request parameters do not satisfy the configured policy. Resource 'safeguardTopic' with retention.ms is '10000', must not be less than '8640000'
```
### Step 6: Alter valid config

If we modify our command to meet the criteria the configuration is altered.

alter topic with valid configs

```bash
docker compose exec kafka-client \
  kafka-configs \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --alter \
    --topic safeguardTopic \
    --add-config retention.ms=86400001
```

Check configs has altered

```bash
docker compose exec kafka-client \
  kafka-configs \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --describe \
    --topic safeguardTopic
```

You should see an output similar to the following:

```
Dynamic configs for topic safeguardTopic are:
  retention.ms=86400001 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.ms=86400001}
```

### Step 7: Log into the platform

> The remaining steps in this demo require a Conduktor Platform license. For more information on this [Arrange a technical demo](https://www.conduktor.io/contact/demo)

Once you have a license key, place it in `platform-config.yaml` under the key: `license` e.g.:

```yaml
license: "eyJhbGciOiJFUzI1NiIsInR5cCI6I..."
```

To start the Conduktor Platform container:

```bash
docker compose --profile platform up --wait --detach
```

From a browser, navigate to `http://localhost:8080` and use the following to log in (as specified in `platform-config.yaml`):

Username: bob@conduktor.io
Password: admin

### Step 8: View the clusters in Conduktor Platform

From Conduktor Platform navigate to Admin -> Clusters, you should see 2 clusters as below:

![clusters](images/clusters.png "Clusters")

### Step 9: View topic configurations with Conduktor Platform

Navigate to `Console` and select the `gateway` cluster from the top right.
You should now see the safeguardTopic topic and clicking on it and select `Configuration` tab.

You should see an output similar to the following:

![alter configs safeguard topic](images/alter_configs_safeguard.png "Alter configs safeguard")
