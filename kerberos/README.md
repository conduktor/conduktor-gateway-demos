# Conduktor Kerberos Demo

## Kerberos

Your backend Kafka cluster may have kerberos security, or OAuth. 
But you want to be able to add a different security mechanism.

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A KDC
* A 3 node Kafka cluster
* A single Conduktor Gateway container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)

### Step 2: Start the environment

Start the environment with

```bash
./start.sh
```

### Step 3: Access your cluster with SASL

```bash
password=$(docker compose exec gateway \
curl \
--user "admin:conduktor" \
--request POST gateway:8888/admin/vclusters/v1/vcluster/someCluster/username/someUsername \
--header "content-type:application/json" \
--data-raw '{"lifeTimeSeconds":7776000}' | jq -r .token)
```

Create a jaas config file

```bash
echo  """
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="someUsername" password="$password";
""" > security/someUsername-jwt.properties
```

Make sure you can use this user information instead of Kerberos to access your kafka

Create a topic 

```bash
docker compose exec cli-kafka \
  kafka-topics \
    --bootstrap-server gateway:6969 \
    --command-config /etc/kafka/secrets/someUsername-jwt.properties \
    --create --if-not-exists \
    --topic my-topic
```

Verify its presence

```bash
docker compose exec cli-kafka \
  kafka-topics \
    --bootstrap-server gateway:6969 \
    --command-config /etc/kafka/secrets/someUsername-jwt.properties \
    --list
```

Then send a message into it

```bash
echo '{"message":"hello world"}' | \
  docker compose exec -T cli-kafka \
    kafka-console-producer \
      --bootstrap-server gateway:6969 \
      --producer.config /etc/kafka/secrets/someUsername-jwt.properties \
      --topic my-topic
```

And consume it back

```bash
docker compose exec cli-kafka \
  kafka-console-consumer \
    --bootstrap-server gateway:6969 \
    --consumer.config /etc/kafka/secrets/someUsername-jwt.properties \
    --topic my-topic \
    --from-beginning \
    --max-messages 1 | jq
````

### Step 4: Tear down

Run 
```bash
./stop.sh
```