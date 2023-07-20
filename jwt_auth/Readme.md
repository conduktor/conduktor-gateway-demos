# Conduktor Gateway JWT Auth Demo

## What is JWT Auth?

Conduktor Gateway includes multi tenancy natively. In order for this to work seamlessly with clients 
the Gateway expects to receive extra information about the tenant a connecting client represents 
during authentication. This information is typically encoded into an encrypted jwt token that is 
created by a Gateway operator. The client then supplies this token in it's security credentials and 
the Gateway validates it before routing accordingly.   

This demo shows you how to generate client tokens and use them in your applications

## Running the demo

### Architecture diagram
![architecture diagram](images/jwt-auth.png "authentication")

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A 2 node Kafka cluster
* A single Conduktor Gateway container
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
docker compose up -d 
echo "Environment started"
```

### Step 4: Configuring the environment

This step is for reference only, the demo is pre-configured in `docker-compose.yaml`

Conduktor Gateway manages user access in a "user pool". These are pluggable so first we must tell it which scheme we wish 
to use:

```bash
      USER_POOL_TYPE: JWT
```

Some pools require further configuration, in this case we require a secret that is used to encrypt any tokens generated 
by the Gateway:

```bash
      USER_POOL_SECRET_KEY: secret
```

Finally we must enable the token generation endpoint:

```bash
      FEATURE_FLAGS_JWT_TOKEN_ENDPOINT: true
```

### Step 5: Generating a token

Tokens are created from calls to a REST endpoint. This endpoint is intended only for use by administrators 
so requires master credentials for use. In this demo, these credentials are configured via environment 
variables on the Gateway container:

```bash
      ADMIN_API_USERS: "[{username: superUser, password: superUser, admin:true}]"
```

In addition to these we need the following information:

1. A tenant name - to determine which part of the cluster these credentials should access.
2. A username

Now that we have these credentials we can create a new token:

```bash
docker compose exec kafka-client  \
  bash -c 'curl \
    --user "admin:conduktor" \
    --header "content-type:application/json" \
    --request POST conduktor-gateway:8888/admin/auth/v1/tenants/someTenant/username/sa \
    --data-raw \{\"lifeTimeSeconds\":7776000\}'
```

This should produce an output similar to this:

```bash
{
  "data" : "eyJhbGciOiJIUzI1NiJ9.eyJvcmdJZCI6MSwiY2x1c3RlcklkIjoiY2x1c3RlcjEiLCJ1c2VybmFtZSI6InRlc3RAY29uZHVrdG9yLmlvIn0.XhB1e_ZXvgZ8zIfr28UQ33S8VA7yfWyfdM561Em9lrM"
}
```

### Step 6: Creating a client configuration

The token should form the password field of a client configuration that uses SASL_PLAIN as it's security mechanism. We 
have created a template ready to receive this token as below:

```bash
docker compose exec kafka-client \
  cat /clientConfig/proxy.properties
```

produces:

```bash
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test@conduktor.io" password="JWT_PLACEHOLDER";
```

let's fill it out:

```bash
docker-compose exec kafka-client  bash -c 'curl \
    -u superUser:superUser \
    --silent \
    -H content-type:application/json \
    --request POST conduktor-proxy:8888/admin/auth/v1beta1/tenants/someTenant \
    --data-raw \{\"lifeTimeSeconds\":7776000\} | cut -d\" -f4 > /tmp/token'
docker-compose exec kafka-client bash -c 'cat \
    /clientConfig/proxy.properties | \
    sed -e s/JWT_PLACEHOLDER/$(</tmp/token)/g \
    > /tmp/jwt.properties'
```

To verify:

```bash
docker-compose exec kafka-client cat /tmp/jwt.properties
```

produces:

```bash
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test@conduktor.io" password="eyJhbGciOiJIUzI1NiJ9.eyJvcmdJZCI6MSwiY2x1c3RlcklkIjoiY2x1c3RlcjEiLCJ1c2VybmFtZSI6InRlc3RAY29uZHVrdG9yLmlvIn0.XhB1e_ZXvgZ8zIfr28UQ33S8VA7yfWyfdM561Em9lrM";
```

### Step 7: Using the token

Let's create a topic, produce and consume some data with the new configuration:

```bash
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/proxy.properties \
    --create \
    --topic tenantTopic
docker-compose exec kafka-client \
  kafka-topics \
    --bootstrap-server conduktor-gateway:6969 \
    --command-config /clientConfig/proxy.properties \
    --list
```

```bash
echo testMessage | docker-compose exec -T kafka-client kafka-console-producer \
    --bootstrap-server conduktor-proxy:6969 \
    --producer.config /tmp/jwt.properties \
    --topic tenantTopic
```

```bash
docker-compose exec kafka-client kafka-console-consumer \
    --bootstrap-server conduktor-proxy:6969 \
    --consumer.config /tmp/jwt.properties \
    --topic tenantTopic \
    --from-beginning
```