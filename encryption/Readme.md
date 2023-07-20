# Conduktor Gateway Encryption Demo

## What is Conduktor Gateway Encryption?

Conduktor Gateway's encryption feature encrypts sensitive fields within messages as they are produced through the Gateway. 

These fields are stored on disk encrypted but can easily be read by clients reading through the Gateway.

### Architecture diagram
![architecture diagram](images/encryption.png "encryption")

### Video

[![asciicast](https://asciinema.org/a/7vzzV57noPXyzL8KPnp1UrP48.svg)](https://asciinema.org/a/7vzzV57noPXyzL8KPnp1UrP48)

## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Gateway container
* A Conduktor Platform container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Review the platform configuration

`platform-config.yaml` defines 2 clusters:

* Backing Kafka - this is a direct connection to the underlying Kafka cluster hosting the demo
* Proxy - a connection through Conduktor Gateway to the underlying Kafka

Note: Gateway and backing Kafka can use different security schemes. 
In this case the backing Kafka is PLAINTEXT but the Gateway is SASL_PLAIN.

### Step 3: Start the environment

Start the environment with

```bash
docker-compose up -d zookeeper kafka1 kafka2 kafka-client schema-registry
sleep 10
docker-compose up -d conduktor-proxy
sleep 5
echo "Environment started"
```

### Step 4: Create topics

We create topics using the Kafka console tools, the below creates a topic named `encryptedTopic`

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic encryptedTopic
```

List the created topic

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --list
```

### Step 5: Configure encryption

The same REST API can be used to configure the encryption feature. 

The command below will instruct Conduktor Gateway to encrypt the `password` and `visa` fields in records on topic `encryptedTopic`. 

```bash
docker-compose exec kafka-client curl \
    -u "superUser:superUser" \
    --silent \
    --request POST "conduktor-proxy:8888/admin/interceptors/v1beta1/tenants/proxy/interceptors/encrypt" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
        "priority": 100,
        "config": {
            "topic": "encryptedTopic",
            "schemaRegistryConfig": {
                "host": "http://schema-registry:8081"
            },
            "fields": [ {
                "fieldName": "password",
                "keySecretId": "password-secret",
                "algorithm": { 
                    "type": "AES_GCM",
                    "kms": "IN_MEMORY"
                }
            },
            {
                "fieldName": "visa",
                "keySecretId": "visa-scret",
                "algorithm": {
                    "type": "AES_GCM",
                    "kms": "IN_MEMORY"
                }
            }]
        }
    }' 
```

and list the interceptors for tenant proxy:

```bash
docker-compose exec kafka-client curl \
    --user "superUser:superUser" \
    conduktor-proxy:8888/admin/interceptors/v1beta1/tenants/proxy/interceptors
```

### Step 6: Configure Decryption

Next we configure Conduktor Gateway to decrypt the fields when fetching data

```bash
docker-compose exec kafka-client curl \
    -u "superUser:superUser" \
    --silent \
    --request POST "conduktor-proxy:8888/admin/interceptors/v1beta1/tenants/proxy/interceptors/decrypt" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.DecryptPlugin",
        "priority": 100,
        "config": {
            "topic": "encryptedTopic",
            "schemaRegistryConfig": {
                "host": "http://schema-registry:8081"
            }
        }
    }'
```

and list the interceptors for tenant proxy:

```bash
docker-compose exec kafka-client curl \
    --user "superUser:superUser" \
    conduktor-proxy:8888/admin/interceptors/v1beta1/tenants/proxy/interceptors
```

### Step 7: Produce data to the topic

Let's produce a simple record to the encrypted topic.

```bash
echo '{ 
    "name": "conduktor",
    "username": "test@conduktor.io",
    "password": "password1",
    "visa": "visa123456",
    "address": "Conduktor Towers, London" 
}' | jq -c | docker-compose exec -T schema-registry \
    kafka-json-schema-console-producer  \
        --bootstrap-server conduktor-proxy:6969 \
        --producer.config /clientConfig/proxy.properties \
        --topic encryptedTopic \
        --property value.schema='{ 
            "title": "User",
            "type": "object",
            "properties": { 
                "name": { "type": "string" },
                "username": { "type": "string" },
                "password": { "type": "string" },
                "visa": { "type": "string" },
                "address": { "type": "string" } 
            } 
        }'
```

### Step 8: Consume from the topic

Let's consume from our `encryptedTopic`.

```bash
docker-compose exec schema-registry \
  kafka-json-schema-console-consumer \
    --bootstrap-server conduktor-proxy:6969 \
    --consumer.config /clientConfig/proxy.properties \
    --topic encryptedTopic \
    --from-beginning \
    --max-messages 1 | jq
```

You should see the encrypted fields have been decrypted on read as below:

```json
{
  "name": "conduktor",
  "username": "test@conduktor.io",
  "password": "password1",
  "visa": "visa123456",
  "address": "Conduktor Towers, London"
}
```

### Step 9: Confirm encryption at rest

To confirm the fields are encrypted in Kafka we can consume directly from the underlying Kafka cluster.

```bash
docker-compose exec schema-registry \
  kafka-json-schema-console-consumer \
    --bootstrap-server kafka1:9092 \
    --topic proxyencryptedTopic \
    --from-beginning \
    --max-messages 1 | jq
```

You should see an output similar to the below:

```json
{
  "name": "conduktor",
  "username": "test@conduktor.io",
  "password": "AUXGXFa8bcMPws2DXsnBTVxzwpWyQusuUsEPWtKItFnGoQoQLd4zSfZjqofomWHdqA==",
  "visa": "ARA3jO6WyWNuhg2wwag0ouLbAGE7fjs+lCAJeXx9J6BZzM/FEiJt5afv4dPf1qNDWS8=",
  "address": "Conduktor Towers, London"
}
```

### Step 10: Log into the platform

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

### Step 11: View the clusters in Conduktor Platform

From Conduktor Platform navigate to Admin -> Clusters, you should see 2 clusters as below:

![clusters](images/clusters.png "Clusters")

### Step 12: View the unencrypted messages in Conduktor Platform

Navigate to `Console` and select the `cdk-gateway` cluster from the top right. You should now see the `encryptedTopic` topic and clicking on it will show you an unencrypted version of the produced message.

![create a topic](images/through_proxy.png "View Unencrypted Messages")

### Step 13: View the encrypted messages in Conduktor Platform

Navigate to `Console` and select the `gateway-backing-cluster` cluster from the cluster selector in the top right. You should now see the `someTenantencryptedTopic` topic (ignore the tenant prefix for now) and clicking on it will show you an encrypted version of the produced message.

![create a topic](images/through_backing_cluster.png "View Encrypted Messages")

### Step 14: Performance impact

[![asciicast](https://asciinema.org/a/IDVSYFYL2xjAQSN2cPhZ7Hfih.svg)](https://asciinema.org/a/IDVSYFYL2xjAQSN2cPhZ7Hfih)

Create a performance topic
```sh
docker-compose exec kafka-client \
    kafka-topics \
        --bootstrap-server conduktor-proxy:6969 \
        --command-config /clientConfig/proxy.properties \
        --create --if-not-exists \
        --topic encryption_performance
```

Let's apply the encryption on this topic

```bash
docker-compose exec kafka-client curl \
    --silent \
    --user "superUser:superUser" \
    --request POST "conduktor-proxy:8888/admin/interceptors/v1beta1/tenants/proxy/interceptors/performanceEncrypt" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "pluginClass": "io.conduktor.gateway.interceptor.EncryptPlugin",
        "priority": 100,
        "config": {
            "topic": "encryption_performance",
            "fields": [ { 
                "fieldName": "password",
                "keySecretId": "password-secret",
                "algorithm": { 
                    "type": "AES_GCM",
                    "kms": "IN_MEMORY"
                }
            },
            { 
                "fieldName": "visa",
                "keySecretId": "visa-secret",
                "algorithm": { 
                    "type": "AES_GCM",
                    "kms": "IN_MEMORY"
                } 
            }]
        }
    }'
```

Let's create a large `customers.json` file with 1 000 000 entries

```sh
printf '{"name":"london","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}\n%.0s' {1..1000000} > customers.json

echo number of lines: `wc -l customers.json | awk '{print $1}'`

echo file size: `du -sh customers.json | awk '{print $1}'`
```

Compute the duration of sending 'customers.json' in gateway with encryption with `kafka-console-producer`

```sh
time docker compose exec -T kafka-client \
    kafka-console-producer  \
        --bootstrap-server conduktor-proxy:6969 \
        --producer.config /clientConfig/proxy.properties \
        --topic encryption_performance < customers.json
```

Verify that we have encrypted messages

```sh
docker-compose exec kafka-client \
    kafka-console-consumer \
        --bootstrap-server conduktor-proxy:6969 \
        --consumer.config /clientConfig/proxy.properties \
        --topic encryption_performance \
        --from-beginning \
        --max-messages 20 | jq
```

Let's do the same with `kafka-producer-perf-test`

```sh
docker compose cp customers.json kafka-client:/home/appuser

docker compose exec kafka-client \
    kafka-producer-perf-test \
        --topic encryption_performance \
        --throughput -1 \
        --num-records 1000000 \
        --producer-props bootstrap.servers=conduktor-proxy:6969 \
        --producer.config /clientConfig/proxy.properties \
        --payload-file customers.json
```