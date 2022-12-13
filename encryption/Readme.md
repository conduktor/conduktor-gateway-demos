# Conduktor Proxy Encryption Demo

## What is Conduktor Proxy Encryption?

Conduktor Proxy's encryption feature encrypts sensitive fields within messages as they are produced through the proxy. 

These fields are stored on disk encrypted but can easily be read by clients reading through the proxy.

### Video

[![asciicast](https://asciinema.org/a/7vzzV57noPXyzL8KPnp1UrP48.svg)](https://asciinema.org/a/7vzzV57noPXyzL8KPnp1UrP48)

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
docker-compose up -d zookeeper kafka1 kafka2 conduktor-proxy kafka-client schema-registry
```

### Step 4: Create topics

We create topics using the Kafka console tools, the below creates a topic named `encrypted_topic`

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --create --if-not-exists \
    --topic encrypted_topic
```

List the created topic

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/proxy.properties \
    --list
```

For field encryption to work we must tell the proxy the format it can expect messages for the newly created topic. 

Conduktor-Proxy presents a REST API for managing Proxy features and the following configures Conduktor Proxy to expect `JSON` format data for topic `encrypted_topic`

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "tenant": "1-1",
        "topic": "encrypted_topic",
        "messageFormat": "JSON"
    }'
```

### Step 5: Configure encryption

The same REST API can be used to configure the encryption feature. 

The command below will instruct Conduktor Proxy to encrypt the `password` and `visa` fields in records on topic `encrypted_topic`. 

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/feature/encryption" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
            "topic": "encrypted_topic",
            "fields": [ { 
                "fieldName": "password",
                "keySecretId": "secret-key-password",
                "algorithm": { 
                    "type": "TINK/AES_GCM",
                    "kms": "TINK/KMS_INMEM" 
                }
            },
            { 
                "fieldName": "visa",
                "keySecretId": "secret-key-visaNumber",
                "algorithm": { 
                    "type": "TINK/AES_GCM",
                    "kms": "TINK/KMS_INMEM" 
                } 
            }] 
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'
```
### Step 6: Configure Decryption

Next we configure Conduktor Proxy to decrypt the fields when fetching data

```bash
docker-compose exec kafka-client curl \
    --silent \
    --request POST "conduktor-proxy:8888/tenant/1-1/feature/decryption" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": { 
            "topic": "encrypted_topic",
            "fields": [ { 
                "fieldName": "password",
                "keySecretId": "secret-key-password",
                "algorithm": { 
                    "type": "TINK/AES_GCM",
                    "kms": "TINK/KMS_INMEM" 
                }
            },
            { 
                "fieldName": "visa",
                "keySecretId": "secret-key-visaNumber",
                "algorithm": { 
                    "type": "TINK/AES_GCM",
                    "kms": "TINK/KMS_INMEM" 
                } 
            }] 
        },
        "direction": "RESPONSE",
        "apiKeys": "FETCH"
    }'
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
        --topic encrypted_topic \
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

Let's consume from our `encrypted_topic`.

```bash
docker-compose exec schema-registry \
  kafka-json-schema-console-consumer \
    --bootstrap-server conduktor-proxy:6969 \
    --consumer.config /clientConfig/proxy.properties \
    --topic encrypted_topic \
    --from-beginning \
    --max-messages 1 | jq .
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
    --topic 1-1encrypted_topic \
    --from-beginning \
    --max-messages 1 | jq .
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

### Step 11: View the clusters in Conduktor Platform

From Conduktor Platform navigate to Admin -> Clusters, you should see 2 clusters as below:

![clusters](images/clusters.png "Clusters")

### Step 12: View the unencrypted messages in Conduktor Platform

Navigate to `Console` and select the `Proxy` cluster from the top right. You should now see the `encrypted_topic` topic and clicking on it will show you an unencrypted version of the produced message.

![create a topic](images/through_proxy.png "View Unencrypted Messages")

### Step 13: View the encrypted messages in Conduktor Platform

Navigate to `Console` and select the `Backing Cluster` cluster from the top right. You should now see the `1-1encrypted_topic` topic (ignore the 1-1 prefix for now) and clicking on it will show you an encrypted version of the produced message.

![create a topic](images/through_backing_cluster.png "View Encrypted Messages")
