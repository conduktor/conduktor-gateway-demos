# Conduktor Gateway JWT Auth Demo

## What is JWT Auth?

To unlock the full potential of Conduktor Gateway you'll want to make use of virtual clusters (VC), a.k.a multi-tenancy. In order for this to work seamlessly with your clients 
the Gateway expects to receive extra information about the tenant (or virtual cluster) a connecting client represents 
during authentication. This information is typically encoded into an encrypted JWT token that is 
created by a Gateway administrator. The client then supplies this token in it's security credentials and 
the Gateway validates it before routing accordingly.   

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
docker-compose up -d zookeeper kafka1 kafka2 kafka-client schema-registry
sleep 10
docker-compose up -d conduktor-proxy
sleep 5
echo "Environment started"
```

### Step 3: Configuring the environment

This step is for reference only, the demo is pre-configured in `docker-compose.yaml`

Conduktor Gateway manages user access in a "user pool", for more information on this or any other part of the configuration details, checkout the [docs site](https://docs.conduktor.io/). These user pools are pluggable so first we must tell it which scheme we wish 
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

### Step 4: Generating a token

With our environment configured we can start generating tokens!
Tokens are created from calls to a REST endpoint. This endpoint is intended only for use by administrators 
so requires master credentials for use. More info about the admin API is available online and can be found from the docs site.
In this demo, these credentials are configured via environment 
variables on the Gateway container:

```bash
      ADMIN_API_USERS: "[{username: superUser, password: superUser, admin:true}]"
```

In addition to the admin credentials for authorisation, we will need the following information to include in the API call:

1. A tenant name - to determine which part of the cluster these credentials should access.
2. A username - to determine who is interacting with the tenant. A user might have additional interceptors applied.

![tenant-user](./images/tenant-user.png)

In our example below let's create a user against `tenantId:someTenant` and `username:someUser`.
Now that we have these credentials and know which tenant & user we wish to interact with, we can create a new token:

```bash
docker-compose exec kafka-client  bash -c 'curl \
    -u superUser:superUser \
    -vvv \
    -H content-type:application/json \
    --request POST conduktor-proxy:8888/admin/auth/v1/tenants/someTenant/username/someUser \
    --data-raw \{\"lifeTimeSeconds\":7776000\}'
```

This should return a JWT, an output similar to this:

```bash
{
  "data" : "eyJhbGciOiJIUzI1NiJ9.eyJvcmdJZCI6MSwiY2x1c3RlcklkIjoiY2x1c3RlcjEiLCJ1c2VybmFtZSI6InRlc3RAY29uZHVrdG9yLmlvIn0.XhB1e_ZXvgZ8zIfr28UQ33S8VA7yfWyfdM561Em9lrM"
}
```

### Step 5: Creating a client configuration

This token should form the password field of a client configuration that uses SASL_PLAIN as it's security mechanism. We 
have created a template ready to receive this token as below. Let's take a quick look at the current provided file:

```bash
docker-compose exec kafka-client cat \
    /clientConfig/proxy.properties
```

should return something similar to:

```bash
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test@conduktor.io" password="JWT_PLACEHOLDER";
```

Let's create a new properties file with our password from the JWT we got back from our curl to the admin API. Make a copy of the file provided, name it `my-jwt.properties`, and paste the token into the field.

Verify your saved change looks similar to the below:

```bash
docker-compose exec kafka-client cat \
    /clientConfig/my-jwt.properties
```

```bash
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test@conduktor.io" password="eyJhbGciOiJIUzI1NiJ9.eyJvcmdJZCI6MSwiY2x1c3RlcklkIjoiY2x1c3RlcjEiLCJ1c2VybmFtZSI6InRlc3RAY29uZHVrdG9yLmlvIn0.XhB1e_ZXvgZ8zIfr28UQ33S8VA7yfWyfdM561Em9lrM";
```

### Step 5: Using the token

Let's create a topic, produce and consume some data with the new configuration:

```bash
docker-compose exec kafka-client kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/my-jwt.properties \
    --create \
    --topic tenantTopic
docker-compose exec kafka-client kafka-topics \
    --bootstrap-server conduktor-proxy:6969 \
    --command-config /clientConfig/my-jwt.properties \
    --list
```

```bash
echo testMessage | docker-compose exec -T kafka-client kafka-console-producer \
    --bootstrap-server conduktor-proxy:6969 \
    --producer.config /clientConfig/my-jwt.properties \
    --topic tenantTopic
```

```bash
docker-compose exec kafka-client kafka-console-consumer \
    --bootstrap-server conduktor-proxy:6969 \
    --consumer.config /clientConfig/my-jwt.properties \
    --topic tenantTopic \
    --from-beginning
```