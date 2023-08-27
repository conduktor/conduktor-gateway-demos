# Creating Virtual Clusters

## Why JWT?

Some features of Conduktor Gateway make use of virtual clusters (VC), a.k.a multi-tenancy, instead of the Passthrough mode.

In order for this to work seamlessly with your clients the Gateway expects to receive extra information about the vcluster (or virtual cluster) a connecting client represents  during authentication. 

This information is typically encoded into an encrypted JWT token that is created by a Gateway administrator. 

The client then supplies this token in it's security credentials and the Gateway validates it before routing accordingly.   

This demo shows you how to generate client tokens and use them in your applications.

## Running the demo

### Architecture diagram
![architecture diagram](images/jwt-auth.png "authentication")

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Gateway container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Start the environment

Start the environment with

```bash
docker compose up --wait --detach
```

### Step 3: Configuring the environment

This step is for reference only, the demo is pre-configured in `docker-compose.yaml`

Conduktor Gateway manages user access in a "user pool".

You may wish to further configure the pool when in production, in this case Gateway requires a secret that is used to encrypt any tokens generated, which can be provided by setting the appropriate environment variable. 

For more information on setting environment variables or any other part of the configuration details, checkout the [docs site](https://docs.conduktor.io/).

You'll also see in the docker compose that Passthrough is set to false as we're turning on multi-tenancy.

### Step 4: Generating a token

With our environment configured we can start generating tokens!  

Tokens are created from calls to a REST endpoint.  This endpoint is intended only for use by administrators so requires master credentials for use. 

More info about the admin API is available online and can be found from the docs site.

In this demo we will use the default values that are already set `ADMIN_API_USERS: "[{username: admin, password: conduktor, admin: true}]`.

In addition to the admin credentials for authorisation, we will need the following information to include in the API call:

1. A virtual cluster name - to determine which part of the cluster these credentials should access.
2. A username - to determine who or which app is interacting with the virtual cluster. A username might have additional interceptors beyond that of the vcluster applied.

![vcluster-user](./images/tenant-user-london.png)

In our example below let's create a username `someUsername` against `vcluster:someCluster`.

```bash
docker compose exec kafka-client \
  curl \
    --silent \
    --user "admin:conduktor" \
    --request POST conduktor-gateway:8888/admin/vclusters/v1/vcluster/someCluster/username/someUsername \
    --header "content-type:application/json" \
    --data-raw '{"lifeTimeSeconds":7776000}' | jq 
```

This should return a JWT, an output similar to:

```bash
{
  "token" : "eyJhbGciOiJIUzI1NiJ9.eyJvcmdJZCI6MSwiY2x1c3RlcklkIjoiY2x1c3RlcjEiLCJ1c2VybmFtZSI6InRlc3RAY29uZHVrdG9yLmlvIn0.XhB1e_ZXvgZ8zIfr28UQ33S8VA7yfWyfdM561Em9lrM"
}
```

### Step 5: Creating a client configuration

This token should form the password field of a generic Kafka client configuration that uses `SASL_PLAIN` as it's security mechanism. 

We have created a template ready to receive this token as below. 

Let's take a quick look at the current provided file, with the below command, or open it in your IDE:

```bash
cat clientConfig/gateway.properties
```

should return something similar to:

```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="someUsername" password="JWT_TOKEN_VALUE";
```

Let's add our JWT, that we just generated from our CURL to the admin API, as the password value. 
Navigate and open the file `gateway.properties`, and paste your token into the password field being careful about the "" marks. 
Or just leave it as is to continue.

Verify your saved changes look similar to the below:

```bash
cat clientConfig/gateway.properties
```

```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="someUsername" password="eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNvbWVVc2VybmFtZSIsInZjbHVzdGVyIjoic29tZUNsdXN0ZXIiLCJleHAiOjIwMDgyOTgzNzJ9.vgTd0QngJQp51gt73HNbHlwjK0m2dW8wD9zRLSZnZd4";
```

### Step 5: Using the token

Let's create a topic, produce and consume some data with the new configuration:

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --create \
    --topic my-topic
```

Observe the created topic in the topic list.

```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/gateway.properties \
    --list
```

Produce a test message.

```bash
echo '{"message": "hello world"}' | \
  docker compose exec -T kafka-client \
    kafka-console-producer \
      --bootstrap-server conduktor-gateway:6969 \
      --producer.config /clientConfig/gateway.properties \
      --topic my-topic
```

Consume the message.

```bash
docker compose exec kafka-client \
  kafka-console-consumer \
    --bootstrap-server conduktor-gateway:6969 \
    --consumer.config /clientConfig/gateway.properties \
    --topic my-topic \
    --from-beginning \
    --max-messages 1 | jq
```


## Conclusion

We have run through the idea of users being created against virtual clusters (vclusters), how this simple environment looks and how we might expand it for a production setup.

That we can create a username as an administrator against the Admin API and get a token back.

That this token should be used as a password for clients connecting to this virtual cluster (vcluster).