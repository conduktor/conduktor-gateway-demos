# Client Id validation



## View the full demo in realtime




You can either follow all the steps manually, or watch the recording

[![asciicast](https://asciinema.org/a/Jpa49o3agxQ176CKz1IUgi4yg.svg)](https://asciinema.org/a/Jpa49o3agxQ176CKz1IUgi4yg)

## Review the docker compose environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following services:

* gateway1
* gateway2
* kafka-client
* kafka1
* kafka2
* kafka3
* schema-registry
* zookeeper

```sh
cat docker-compose.yaml
```

<details>
<summary>File content</summary>

```yaml
version: '3.7'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    hostname: zookeeper
    container_name: zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2801
      ZOOKEEPER_TICK_TIME: 2000
    healthcheck:
      test: nc -zv 0.0.0.0 2801 || exit 1
      interval: 5s
      retries: 25
  kafka1:
    hostname: kafka1
    container_name: kafka1
    image: confluentinc/cp-kafka:latest
    ports:
    - 19092:19092
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801
      KAFKA_LISTENERS: INTERNAL://:9092,EXTERNAL_SAME_HOST://:19092
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka1:9092,EXTERNAL_SAME_HOST://localhost:19092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper:
        condition: service_healthy
    healthcheck:
      test: nc -zv kafka1 9092 || exit 1
      interval: 5s
      retries: 25
  kafka2:
    hostname: kafka2
    container_name: kafka2
    image: confluentinc/cp-kafka:latest
    ports:
    - 19093:19093
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801
      KAFKA_LISTENERS: INTERNAL://:9093,EXTERNAL_SAME_HOST://:19093
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka2:9093,EXTERNAL_SAME_HOST://localhost:19093
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper:
        condition: service_healthy
    healthcheck:
      test: nc -zv kafka2 9093 || exit 1
      interval: 5s
      retries: 25
  kafka3:
    image: confluentinc/cp-kafka:latest
    hostname: kafka3
    container_name: kafka3
    ports:
    - 19094:19094
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2801
      KAFKA_LISTENERS: INTERNAL://:9094,EXTERNAL_SAME_HOST://:19094
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka3:9094,EXTERNAL_SAME_HOST://localhost:19094
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL_SAME_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_LOG4J_LOGGERS: kafka.authorizer.logger=INFO
      KAFKA_LOG4J_ROOT_LOGLEVEL: WARN
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: false
    depends_on:
      zookeeper:
        condition: service_healthy
    healthcheck:
      test: nc -zv kafka3 9094 || exit 1
      interval: 5s
      retries: 25
  schema-registry:
    image: confluentinc/cp-schema-registry:latest
    hostname: schema-registry
    container_name: schema-registry
    ports:
    - 8081:8081
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      SCHEMA_REGISTRY_LOG4J_ROOT_LOGLEVEL: WARN
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
      SCHEMA_REGISTRY_KAFKASTORE_TOPIC: _schemas
      SCHEMA_REGISTRY_SCHEMA_REGISTRY_GROUP_ID: schema-registry
    volumes:
    - type: bind
      source: .
      target: /clientConfig
      read_only: true
    depends_on:
      kafka1:
        condition: service_healthy
      kafka2:
        condition: service_healthy
      kafka3:
        condition: service_healthy
    healthcheck:
      test: nc -zv schema-registry 8081 || exit 1
      interval: 5s
      retries: 25
  gateway1:
    image: conduktor/conduktor-gateway:3.0.0
    hostname: gateway1
    container_name: gateway1
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_MODE: VCLUSTER
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
    depends_on:
      kafka1:
        condition: service_healthy
      kafka2:
        condition: service_healthy
      kafka3:
        condition: service_healthy
    ports:
    - 6969:6969
    - 6970:6970
    - 6971:6971
    - 8888:8888
    healthcheck:
      test: curl localhost:8888/health
      interval: 5s
      retries: 25
  gateway2:
    image: conduktor/conduktor-gateway:3.0.0
    hostname: gateway2
    container_name: gateway2
    environment:
      KAFKA_BOOTSTRAP_SERVERS: kafka1:9092,kafka2:9093,kafka3:9094
      GATEWAY_ADVERTISED_HOST: localhost
      GATEWAY_MODE: VCLUSTER
      GATEWAY_SECURITY_PROTOCOL: SASL_PLAINTEXT
      GATEWAY_FEATURE_FLAGS_ANALYTICS: false
      GATEWAY_START_PORT: 7969
    depends_on:
      kafka1:
        condition: service_healthy
      kafka2:
        condition: service_healthy
      kafka3:
        condition: service_healthy
    ports:
    - 7969:7969
    - 7970:7970
    - 7971:7971
    - 8889:8888
    healthcheck:
      test: curl localhost:8888/health
      interval: 5s
      retries: 25
  kafka-client:
    image: confluentinc/cp-kafka:latest
    hostname: kafka-client
    container_name: kafka-client
    command: sleep infinity
    volumes:
    - type: bind
      source: .
      target: /clientConfig
      read_only: true
networks:
  demo: null
```

</details>

## Starting the docker environment

Start all your docker processes, wait for them to be up and ready, then run in background

* `--wait`: Wait for services to be `running|healthy`. Implies detached mode.
* `--detach`: Detached mode: Run containers in the background

<details open>
<summary>Command</summary>



```sh
docker compose up --detach --wait
```



</details>
<details>
<summary>Output</summary>

```
 Network safeguard-client-id_default  Creating
 Network safeguard-client-id_default  Created
 Container zookeeper  Creating
 Container kafka-client  Creating
 Container kafka-client  Created
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka2  Creating
 Container kafka1  Creating
 Container kafka3  Created
 Container kafka1  Created
 Container kafka2  Created
 Container gateway2  Creating
 Container gateway1  Creating
 Container schema-registry  Creating
 Container gateway1  Created
 Container gateway2  Created
 Container schema-registry  Created
 Container zookeeper  Starting
 Container kafka-client  Starting
 Container kafka-client  Started
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container kafka3  Started
 Container kafka2  Started
 Container kafka1  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway2  Starting
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka2  Healthy
 Container gateway1  Starting
 Container schema-registry  Started
 Container gateway1  Started
 Container gateway2  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container kafka-client  Waiting
 Container zookeeper  Waiting
 Container kafka1  Waiting
 Container kafka1  Healthy
 Container zookeeper  Healthy
 Container kafka2  Healthy
 Container kafka-client  Healthy
 Container kafka3  Healthy
 Container gateway2  Healthy
 Container gateway1  Healthy
 Container schema-registry  Healthy

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/J7vjTNtu8IAr3ZxALLOY5EW7s.svg)](https://asciinema.org/a/J7vjTNtu8IAr3ZxALLOY5EW7s)

</details>

## Creating virtual cluster teamA

Creating virtual cluster `teamA` on gateway `gateway1` and reviewing the configuration file to access it

<details>
<summary>Command</summary>



```sh
# Generate virtual cluster teamA with service account sa
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

# Create access file
echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > teamA-sa.properties

# Review file
cat teamA-sa.properties
```



</details>
<details>
<summary>Output</summary>

```

bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ4MDEzOH0.hGXNV3aTV9TNMgWU3RUsQwJtc0z6Z1hA4GsvAd0SJyQ';


```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/HM2HWI0XrfhoyQ34ZWCn5S49g.svg)](https://asciinema.org/a/HM2HWI0XrfhoyQ34ZWCn5S49g)

</details>

## Creating topic users on teamA

Creating on `teamA`:

* Topic `users` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic users
```



</details>
<details>
<summary>Output</summary>

```
Created topic users.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/JsfRICS3TYP4gyL66vOt8sMgv.svg)](https://asciinema.org/a/JsfRICS3TYP4gyL66vOt8sMgv)

</details>

## Listing topics in teamA



<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
```



</details>
<details>
<summary>Output</summary>

```
users

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/ORBGV6pstTIzBErnESqbXDXpk.svg)](https://asciinema.org/a/ORBGV6pstTIzBErnESqbXDXpk)

</details>

## Adding interceptor client-id



Creating the interceptor named `client-id` of the plugin `io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin` using the following payload

```json
{
  "pluginClass" : "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
  "priority" : 100,
  "config" : {
    "namingConvention" : "naming-convention-.*"
  }
}
```

Here's how to send it:

<details open>
<summary>Command</summary>



```sh
cat step-08-client-id.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/client-id" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-client-id.json | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
  "priority": 100,
  "config": {
    "namingConvention": "naming-convention-.*"
  }
}
{
  "message": "client-id is created"
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/NB45xTNBy9TAtQZdLW0iiwJfB.svg)](https://asciinema.org/a/NB45xTNBy9TAtQZdLW0iiwJfB)

</details>

## Listing interceptors for teamA

Listing interceptors on `gateway1` for virtual cluster `teamA`

<details open>
<summary>Command</summary>



```sh
curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/teamA' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
```



</details>
<details>
<summary>Output</summary>

```json
{
  "interceptors": [
    {
      "name": "client-id",
      "pluginClass": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "namingConvention": "naming-convention-.*"
      }
    }
  ]
}

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/j3UhMm6IRcZKFBdv4ghBOcv4W.svg)](https://asciinema.org/a/j3UhMm6IRcZKFBdv4ghBOcv4W)

</details>

## Creating topic customers on teamA

Creating on `teamA`:

* Topic `customers` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic customers
```

> [!IMPORTANT]
> We get the following exception
>
> ```sh
> org.apache.kafka.common.errors.PolicyViolationException:
>> clientId 'adminclient-16' is invalid, naming convention must match with regular expression 'naming-convention-.*'
> ```





</details>
<details>
<summary>Output</summary>

```
[2024-04-10 03:09:02,563] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 0. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:02,689] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 1. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:02,806] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 2. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:03,047] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 3. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:03,476] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 4. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:04,313] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 5. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:05,360] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 6. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:06,411] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 7. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:07,484] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 8. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:08,557] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 9. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:09,619] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 10. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:10,668] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 11. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:11,738] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 12. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:12,784] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 13. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:13,829] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 14. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:14,891] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 15. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:15,940] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 16. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:16,988] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 17. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:18,038] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 18. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:18,981] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 19. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:20,023] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 20. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:21,079] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 21. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:22,126] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 22. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:23,067] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 23. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:24,106] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 24. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:25,068] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 25. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:26,008] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 26. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:26,977] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 27. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:28,011] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 28. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:29,046] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 29. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:29,974] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 30. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:31,032] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 31. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:32,087] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 32. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:33,135] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 33. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:34,074] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 34. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:35,123] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 35. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:36,168] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 36. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:37,120] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 37. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:38,154] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 38. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:39,201] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 39. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:40,256] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 40. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:41,308] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 41. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:42,370] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 42. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:43,425] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 43. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:44,486] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 44. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:45,513] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 45. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:46,444] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 46. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:47,384] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 47. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:48,415] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 48. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:49,462] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 49. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:50,509] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 50. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:51,562] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 51. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:52,504] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 52. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:53,456] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 53. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:54,490] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 54. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:55,534] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 55. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:56,476] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 56. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:57,409] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 57. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:58,446] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 58. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:09:59,490] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 59. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:10:00,547] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 60. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:10:01,376] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 61. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-04-10 03:10:02,409] WARN [AdminClient clientId=adminclient-1] Received error POLICY_VIOLATION from node -1 when making an ApiVersionsRequest with correlation id 62. Disconnecting. (org.apache.kafka.clients.NetworkClient)
Error while executing topic command : Timed out waiting for a node assignment. Call: createTopics
[2024-04-10 03:10:02,418] ERROR org.apache.kafka.common.errors.TimeoutException: Timed out waiting for a node assignment. Call: createTopics
 (org.apache.kafka.tools.TopicCommand)

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/scj562M8MBgbnKR2IGzJcfxVz.svg)](https://asciinema.org/a/scj562M8MBgbnKR2IGzJcfxVz)

</details>

## Let's update the client id to match the convention



<details open>
<summary>Command</summary>



```sh
echo >> teamA-sa.properties    
echo "client.id=naming-convention-for-this-application" >> teamA-sa.properties    
```



</details>
<details>
<summary>Output</summary>

```

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/KAEWiUTWWJ7RRKyFg0zrV9Uz8.svg)](https://asciinema.org/a/KAEWiUTWWJ7RRKyFg0zrV9Uz8)

</details>

## Creating topic customers on teamA

Creating on `teamA`:

* Topic `customers` with partitions:1 and replication-factor:1

<details open>
<summary>Command</summary>



```sh
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic customers
```



</details>
<details>
<summary>Output</summary>

```
Created topic customers.

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/5cu43XG4Yym0h8Bc1wVu9Nj36.svg)](https://asciinema.org/a/5cu43XG4Yym0h8Bc1wVu9Nj36)

</details>

## Check in the audit log that produce was denied

Check in the audit log that produce was denied in cluster `kafka1`

<details open>
<summary>Command</summary>



```sh
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _conduktor_gateway_auditlogs \
    --from-beginning \
    --timeout-ms 3000 \| jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin")'
```


returns 1 event
```json
{
  "id" : "91c45f36-e265-4941-b796-af3078b4f731",
  "source" : "krn://cluster=eG1hLB1OQfiiMLDC-ra_qw",
  "type" : "SAFEGUARD",
  "authenticationPrincipal" : "teamA",
  "userName" : "sa",
  "connection" : {
    "localAddress" : null,
    "remoteAddress" : "/192.168.65.1:19753"
  },
  "specVersion" : "0.1.0",
  "time" : "2024-04-09T23:08:31.898847376Z",
  "eventData" : {
    "level" : "error",
    "plugin" : "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message" : "clientId 'adminclient-16' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
```



</details>
<details>
<summary>Output</summary>

```
{"id":"fc31b8ea-6b5b-432f-8f87-448da6b5d8cd","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"172.23.0.8:8888","remoteAddress":"192.168.65.1:31542"},"specVersion":"0.1.0","time":"2024-04-09T23:08:58.836842680Z","eventData":{"method":"POST","path":"/admin/vclusters/v1/vcluster/teamA/username/sa","body":"{\"lifeTimeSeconds\": 7776000}"}}
{"id":"e089143f-b6cc-41c3-81fe-0c5d550db5ae","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20120"},"specVersion":"0.1.0","time":"2024-04-09T23:08:59.811710833Z","eventData":"SUCCESS"}
{"id":"d5b428cf-4f6d-48ea-820a-6c2b7c1dd005","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6970","remoteAddress":"/192.168.65.1:36011"},"specVersion":"0.1.0","time":"2024-04-09T23:08:59.867349041Z","eventData":"SUCCESS"}
{"id":"848abec4-2cd8-458b-a9f1-a915d31498cc","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20122"},"specVersion":"0.1.0","time":"2024-04-09T23:09:01.126586459Z","eventData":"SUCCESS"}
{"id":"5a9e2144-21df-41e1-8752-db8c6541e69b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6970","remoteAddress":"/192.168.65.1:36013"},"specVersion":"0.1.0","time":"2024-04-09T23:09:01.153179250Z","eventData":"SUCCESS"}
{"id":"d10cbb53-b18a-4faf-b72c-ab9903b0c1d7","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"172.23.0.8:8888","remoteAddress":"192.168.65.1:31547"},"specVersion":"0.1.0","time":"2024-04-09T23:09:01.654008459Z","eventData":{"method":"POST","path":"/admin/interceptors/v1/vcluster/teamA/interceptor/client-id","body":"{  \"pluginClass\" : \"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin\",  \"priority\" : 100,  \"config\" : {    \"namingConvention\" : \"naming-convention-.*\"  }}"}}
{"id":"cba27a90-65a9-406c-82c1-d59d83cb7413","source":"Optional.empty","type":"REST_API","authenticationPrincipal":"admin","userName":null,"connection":{"localAddress":"172.23.0.8:8888","remoteAddress":"192.168.65.1:31548"},"specVersion":"0.1.0","time":"2024-04-09T23:09:01.762245917Z","eventData":{"method":"GET","path":"/admin/interceptors/v1/vcluster/teamA","body":null}}
{"id":"b947e003-dcdf-4c61-a009-0502a325b917","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20126"},"specVersion":"0.1.0","time":"2024-04-09T23:09:02.546377043Z","eventData":"SUCCESS"}
{"id":"f139cecb-1d08-49d4-9b82-2330c7cecb9c","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20126"},"specVersion":"0.1.0","time":"2024-04-09T23:09:02.555821209Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"aa7c82fb-ef1e-4c8c-b31c-21228d38c47f","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20127"},"specVersion":"0.1.0","time":"2024-04-09T23:09:02.683298918Z","eventData":"SUCCESS"}
{"id":"104cdf1d-3ab2-4bb0-b30a-5ef329e93df2","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20127"},"specVersion":"0.1.0","time":"2024-04-09T23:09:02.686989668Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"24e18fef-1a1d-4a5e-85ec-81acf83363a2","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20128"},"specVersion":"0.1.0","time":"2024-04-09T23:09:02.801116459Z","eventData":"SUCCESS"}
{"id":"24ee215c-0041-44d4-813e-45205dbca257","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20128"},"specVersion":"0.1.0","time":"2024-04-09T23:09:02.804430668Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"28518b92-be26-4f54-9868-257511d00122","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20129"},"specVersion":"0.1.0","time":"2024-04-09T23:09:03.040759626Z","eventData":"SUCCESS"}
{"id":"544abc7d-2cdd-4811-8672-0231f9ac5614","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20129"},"specVersion":"0.1.0","time":"2024-04-09T23:09:03.044805460Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"978eabc7-cb61-4ff0-bc08-5598a71fd5a6","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20130"},"specVersion":"0.1.0","time":"2024-04-09T23:09:03.467672835Z","eventData":"SUCCESS"}
{"id":"5943bbb0-6444-41a1-9912-4f5d81fac3a3","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20130"},"specVersion":"0.1.0","time":"2024-04-09T23:09:03.472944710Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"14db9337-0422-4767-9eba-bfcae8bfe763","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20131"},"specVersion":"0.1.0","time":"2024-04-09T23:09:04.306340043Z","eventData":"SUCCESS"}
{"id":"cfda6756-4520-48a4-b24e-f5deaa109935","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20131"},"specVersion":"0.1.0","time":"2024-04-09T23:09:04.310841418Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"744e1f5f-7daf-4646-a2ad-8b84a682be00","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20132"},"specVersion":"0.1.0","time":"2024-04-09T23:09:05.353869252Z","eventData":"SUCCESS"}
{"id":"c350879c-da08-4462-b569-9227c5007b5f","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20132"},"specVersion":"0.1.0","time":"2024-04-09T23:09:05.357649711Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"a4e8609a-7ad4-41fe-b0f5-41905e7ca349","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20133"},"specVersion":"0.1.0","time":"2024-04-09T23:09:06.402573919Z","eventData":"SUCCESS"}
{"id":"20d037a9-0061-48b7-8170-e29343f54567","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20133"},"specVersion":"0.1.0","time":"2024-04-09T23:09:06.407965503Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"f78e06ba-1b97-49cd-a7bd-731866cf8ff9","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20134"},"specVersion":"0.1.0","time":"2024-04-09T23:09:07.461732462Z","eventData":"SUCCESS"}
{"id":"4dc6462a-ba4a-4cb4-8687-1e61a6a1d940","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20134"},"specVersion":"0.1.0","time":"2024-04-09T23:09:07.481773128Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"99a1060e-4c2f-4922-a605-893637ebba15","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20159"},"specVersion":"0.1.0","time":"2024-04-09T23:09:08.542121129Z","eventData":"SUCCESS"}
{"id":"31dddbed-ad15-4e8c-ac53-cd5fc1259b00","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20159"},"specVersion":"0.1.0","time":"2024-04-09T23:09:08.553854504Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"330ace5f-9f19-49ed-aa7b-cb663ba53c93","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20160"},"specVersion":"0.1.0","time":"2024-04-09T23:09:09.608932463Z","eventData":"SUCCESS"}
{"id":"98865dbc-3335-44b6-87fe-aae202a43da2","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20160"},"specVersion":"0.1.0","time":"2024-04-09T23:09:09.615198838Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"bc4ca401-b166-4162-bdea-c203f2d4ff2d","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20161"},"specVersion":"0.1.0","time":"2024-04-09T23:09:10.653495255Z","eventData":"SUCCESS"}
{"id":"f4f83d56-3160-4b42-92af-0ebc5bc62af1","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20161"},"specVersion":"0.1.0","time":"2024-04-09T23:09:10.659489088Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"a05a221b-c2ac-496d-9037-0e5c841329fb","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20162"},"specVersion":"0.1.0","time":"2024-04-09T23:09:11.724711547Z","eventData":"SUCCESS"}
{"id":"32b23f21-8e2f-4b23-9135-c1854c079ba4","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20162"},"specVersion":"0.1.0","time":"2024-04-09T23:09:11.733973005Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"dbd39024-77d7-4b05-a04d-57ee0dddf081","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20163"},"specVersion":"0.1.0","time":"2024-04-09T23:09:12.771706548Z","eventData":"SUCCESS"}
{"id":"c8c2e8fc-ca14-40e5-a3d0-23828b264952","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20163"},"specVersion":"0.1.0","time":"2024-04-09T23:09:12.774950214Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"703b63f1-b4b2-4678-acd0-d357b91825af","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20164"},"specVersion":"0.1.0","time":"2024-04-09T23:09:13.820804465Z","eventData":"SUCCESS"}
{"id":"6e535df9-8726-4105-8459-94f1e51c6545","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20164"},"specVersion":"0.1.0","time":"2024-04-09T23:09:13.825875381Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"9a06fbbd-4333-4c33-a41f-036e2e8bb668","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20165"},"specVersion":"0.1.0","time":"2024-04-09T23:09:14.883042340Z","eventData":"SUCCESS"}
{"id":"140fd6ea-cbd3-47c6-a093-0d2854cd1735","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20165"},"specVersion":"0.1.0","time":"2024-04-09T23:09:14.888253507Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"4dc530f1-a36b-4559-882f-4cc8136df4f2","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20166"},"specVersion":"0.1.0","time":"2024-04-09T23:09:15.932068091Z","eventData":"SUCCESS"}
{"id":"e7138373-6bc7-4c89-b2b9-32720e8be17b","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20166"},"specVersion":"0.1.0","time":"2024-04-09T23:09:15.936781091Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"4212a717-d4f7-45fd-961e-892113a0defd","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20167"},"specVersion":"0.1.0","time":"2024-04-09T23:09:16.977738675Z","eventData":"SUCCESS"}
{"id":"43bbb36d-ae5c-4362-af26-55bcd703ad5f","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20167"},"specVersion":"0.1.0","time":"2024-04-09T23:09:16.982852050Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"4a91a3ba-9236-4bef-8d95-7256046b8795","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20180"},"specVersion":"0.1.0","time":"2024-04-09T23:09:18.021041967Z","eventData":"SUCCESS"}
{"id":"6d134748-7819-4862-b740-f4c36ba3aeb7","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20180"},"specVersion":"0.1.0","time":"2024-04-09T23:09:18.035556633Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"7efaa6f8-858f-4ec5-98a8-70e784d227e0","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20193"},"specVersion":"0.1.0","time":"2024-04-09T23:09:18.972826467Z","eventData":"SUCCESS"}
{"id":"c0d27232-1c4a-436b-b71c-eaee05a5bad3","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20193"},"specVersion":"0.1.0","time":"2024-04-09T23:09:18.978516425Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"807e7922-f9b9-4e18-b2a9-2e4d8b91378f","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20194"},"specVersion":"0.1.0","time":"2024-04-09T23:09:20.014942176Z","eventData":"SUCCESS"}
{"id":"74006eea-a2d9-4a03-91e9-727153437727","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20194"},"specVersion":"0.1.0","time":"2024-04-09T23:09:20.020215384Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"b005a991-bf61-4b14-bd51-1abda0dce2c5","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20195"},"specVersion":"0.1.0","time":"2024-04-09T23:09:21.070354260Z","eventData":"SUCCESS"}
{"id":"04fc9259-ea81-4d0f-bfca-d4debc617606","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20195"},"specVersion":"0.1.0","time":"2024-04-09T23:09:21.075887926Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"7a47d388-d3a7-4212-852e-ffe46595c6e4","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20196"},"specVersion":"0.1.0","time":"2024-04-09T23:09:22.122334219Z","eventData":"SUCCESS"}
{"id":"51e781ec-6862-4773-9808-71175ae9fa58","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20196"},"specVersion":"0.1.0","time":"2024-04-09T23:09:22.124761344Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"f58da823-7a6a-4e46-b29c-e8d07d07bd8d","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20197"},"specVersion":"0.1.0","time":"2024-04-09T23:09:23.059829969Z","eventData":"SUCCESS"}
{"id":"dcff6035-6da7-43a0-9a14-54ff7ee781a7","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20197"},"specVersion":"0.1.0","time":"2024-04-09T23:09:23.064491386Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"eacdcbe6-c260-458c-8f02-2b3baa39411d","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20198"},"specVersion":"0.1.0","time":"2024-04-09T23:09:24.098265428Z","eventData":"SUCCESS"}
{"id":"04adbfb4-94b9-4c42-9853-7576eca00fae","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20198"},"specVersion":"0.1.0","time":"2024-04-09T23:09:24.103639261Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"3381de6f-48d7-4ce4-a2a7-9954e361d71f","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20199"},"specVersion":"0.1.0","time":"2024-04-09T23:09:25.059878387Z","eventData":"SUCCESS"}
{"id":"093cf8de-9788-4808-a694-833a8a5e1abc","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20199"},"specVersion":"0.1.0","time":"2024-04-09T23:09:25.064730553Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"de86a42a-3a2e-4163-8d93-e2ec1d4be587","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20200"},"specVersion":"0.1.0","time":"2024-04-09T23:09:26.000083679Z","eventData":"SUCCESS"}
{"id":"689ba89b-246c-4c0d-8e25-ac16310117cd","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20200"},"specVersion":"0.1.0","time":"2024-04-09T23:09:26.004666804Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"4ac67267-21bf-49ef-8e09-fe589609efaf","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20201"},"specVersion":"0.1.0","time":"2024-04-09T23:09:26.967065971Z","eventData":"SUCCESS"}
{"id":"ae74408a-3b85-4d06-8357-6c6b4c3d9fad","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20201"},"specVersion":"0.1.0","time":"2024-04-09T23:09:26.973353846Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"6fe8a626-4275-439b-ab44-e9e3773ae146","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20214"},"specVersion":"0.1.0","time":"2024-04-09T23:09:28.004792680Z","eventData":"SUCCESS"}
{"id":"15ac7e33-c29c-4fac-929f-9c74d1fa8f5a","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20214"},"specVersion":"0.1.0","time":"2024-04-09T23:09:28.008884805Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"2adf839c-eb35-4ebb-9ce0-eaf83388929d","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20227"},"specVersion":"0.1.0","time":"2024-04-09T23:09:29.041644055Z","eventData":"SUCCESS"}
{"id":"4b48916a-39e4-4468-be65-91f9e7374d1f","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20227"},"specVersion":"0.1.0","time":"2024-04-09T23:09:29.044621847Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"bae1fa04-19cb-44d5-8a94-fe53378bb615","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20228"},"specVersion":"0.1.0","time":"2024-04-09T23:09:29.966305791Z","eventData":"SUCCESS"}
{"id":"9e203f2f-c36d-46aa-a8ea-5d5f2380c8c0","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20228"},"specVersion":"0.1.0","time":"2024-04-09T23:09:29.968505Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"26aaf7f5-e666-48e2-a5b0-b5af63dcddd5","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20229"},"specVersion":"0.1.0","time":"2024-04-09T23:09:31.020777542Z","eventData":"SUCCESS"}
{"id":"a86edb2c-a0e4-42dc-833b-7b36cf5ce60d","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20229"},"specVersion":"0.1.0","time":"2024-04-09T23:09:31.025440917Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"4c69361e-800a-4d0d-ab63-50db58ce2a4c","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20230"},"specVersion":"0.1.0","time":"2024-04-09T23:09:32.071779042Z","eventData":"SUCCESS"}
{"id":"58502afe-7ef6-41d2-bd81-bc3871cc3aad","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20230"},"specVersion":"0.1.0","time":"2024-04-09T23:09:32.078063542Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"b6cbde9f-3d70-4a3b-9cae-2a4658f6f43a","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20231"},"specVersion":"0.1.0","time":"2024-04-09T23:09:33.126890001Z","eventData":"SUCCESS"}
{"id":"58d00865-d189-4a9f-8e7b-d47d74a811c5","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20231"},"specVersion":"0.1.0","time":"2024-04-09T23:09:33.129547460Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"faafee5a-ead5-4bc2-9df5-a0ca797c31c5","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20232"},"specVersion":"0.1.0","time":"2024-04-09T23:09:34.063020752Z","eventData":"SUCCESS"}
{"id":"4ccc796c-29e4-40e4-b074-4c320f944521","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20232"},"specVersion":"0.1.0","time":"2024-04-09T23:09:34.067340710Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"2ac2aa75-4f55-4386-8dc6-4d0c8821d46b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20233"},"specVersion":"0.1.0","time":"2024-04-09T23:09:35.110253294Z","eventData":"SUCCESS"}
{"id":"6a1e1d1c-5151-4f6b-8394-84b64b1ee663","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20233"},"specVersion":"0.1.0","time":"2024-04-09T23:09:35.114732336Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"b5e8b61c-1193-45d2-856b-4da0d36b7cea","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20234"},"specVersion":"0.1.0","time":"2024-04-09T23:09:36.155828919Z","eventData":"SUCCESS"}
{"id":"81809090-3a86-48dc-9861-63e5af75be64","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20234"},"specVersion":"0.1.0","time":"2024-04-09T23:09:36.160443836Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"ff891f9d-18a2-48d5-8ce9-8cdcda813f3d","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20235"},"specVersion":"0.1.0","time":"2024-04-09T23:09:37.106920503Z","eventData":"SUCCESS"}
{"id":"efaa780d-6158-4015-b7ca-a9db22321327","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20235"},"specVersion":"0.1.0","time":"2024-04-09T23:09:37.111953920Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"66bfd839-0791-48da-991f-b5f24e4b0742","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20248"},"specVersion":"0.1.0","time":"2024-04-09T23:09:38.141417045Z","eventData":"SUCCESS"}
{"id":"42212e4b-2175-48d0-8660-079061f7012d","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20248"},"specVersion":"0.1.0","time":"2024-04-09T23:09:38.148142920Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"5d39d817-2267-4dc0-b470-d03f7115d682","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20261"},"specVersion":"0.1.0","time":"2024-04-09T23:09:39.186748129Z","eventData":"SUCCESS"}
{"id":"eb4aea95-c46b-4e60-8569-75924f0edf49","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20261"},"specVersion":"0.1.0","time":"2024-04-09T23:09:39.192506587Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"63ea5edb-b3ab-4edf-b99c-a3bc16bec9e6","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20262"},"specVersion":"0.1.0","time":"2024-04-09T23:09:40.240773088Z","eventData":"SUCCESS"}
{"id":"6d9d37d4-7ff1-434e-bec2-866aa05f3156","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20262"},"specVersion":"0.1.0","time":"2024-04-09T23:09:40.249178796Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"f712ac67-1781-4cc4-825c-041eddf879e8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20263"},"specVersion":"0.1.0","time":"2024-04-09T23:09:41.299118880Z","eventData":"SUCCESS"}
{"id":"f62a50b9-c046-425e-a090-dcaac9f93d29","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20263"},"specVersion":"0.1.0","time":"2024-04-09T23:09:41.302156797Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"e6bf280a-b2cf-4073-9e80-b85fdff1e063","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20264"},"specVersion":"0.1.0","time":"2024-04-09T23:09:42.357143381Z","eventData":"SUCCESS"}
{"id":"2c154dbc-c7c2-4dee-b3bd-2c87f01ce44a","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20264"},"specVersion":"0.1.0","time":"2024-04-09T23:09:42.362546631Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"cfc80b4b-9dab-423d-a82f-33a45f5d8120","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20265"},"specVersion":"0.1.0","time":"2024-04-09T23:09:43.411806131Z","eventData":"SUCCESS"}
{"id":"7a7ae415-9aa9-4ae0-b294-855acaca9895","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20265"},"specVersion":"0.1.0","time":"2024-04-09T23:09:43.417888173Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"d2ab9d1e-8d45-4ae8-a2e3-05f8220cdce8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20266"},"specVersion":"0.1.0","time":"2024-04-09T23:09:44.468970715Z","eventData":"SUCCESS"}
{"id":"c77e5796-e6bd-41a2-a247-3e69ef056f9a","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20266"},"specVersion":"0.1.0","time":"2024-04-09T23:09:44.479822548Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"7649ad2d-d3fa-4b7e-88f9-31d8b03e42c1","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20267"},"specVersion":"0.1.0","time":"2024-04-09T23:09:45.504890257Z","eventData":"SUCCESS"}
{"id":"f7dd4598-92b5-4cc9-a3aa-aba063398a37","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20267"},"specVersion":"0.1.0","time":"2024-04-09T23:09:45.507338799Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"1e827745-44d6-4d7d-af20-ba83c5161a1b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20268"},"specVersion":"0.1.0","time":"2024-04-09T23:09:46.431372049Z","eventData":"SUCCESS"}
{"id":"fdd32c16-6d71-4972-bf92-1e9ed6313c33","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20268"},"specVersion":"0.1.0","time":"2024-04-09T23:09:46.436297591Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"32ce9f75-fa63-46de-9127-8110e2aa3e68","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20269"},"specVersion":"0.1.0","time":"2024-04-09T23:09:47.375119675Z","eventData":"SUCCESS"}
{"id":"609953b0-e7d0-4fdf-a5ca-c320255b7d4e","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20269"},"specVersion":"0.1.0","time":"2024-04-09T23:09:47.377839300Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"3a53611a-7aec-4683-a260-a58c80d97b6a","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20282"},"specVersion":"0.1.0","time":"2024-04-09T23:09:48.405223509Z","eventData":"SUCCESS"}
{"id":"9512aa79-a2a2-4ade-b57a-55ee91117b0e","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20282"},"specVersion":"0.1.0","time":"2024-04-09T23:09:48.408932467Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"33b7f6fd-00ad-4ead-a30b-39e75daf1f5c","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20295"},"specVersion":"0.1.0","time":"2024-04-09T23:09:49.448602467Z","eventData":"SUCCESS"}
{"id":"7fd86aab-1a02-471b-af70-2c52c22759e1","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20295"},"specVersion":"0.1.0","time":"2024-04-09T23:09:49.454952426Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"9302749e-708b-40d4-9098-2dbedb73c088","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20296"},"specVersion":"0.1.0","time":"2024-04-09T23:09:50.496302218Z","eventData":"SUCCESS"}
{"id":"c6c42a80-6534-4423-ab25-c76e29bef8a9","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20296"},"specVersion":"0.1.0","time":"2024-04-09T23:09:50.502023010Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"d7184b39-a254-48cd-abd8-ae08073e0e6f","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20297"},"specVersion":"0.1.0","time":"2024-04-09T23:09:51.552708177Z","eventData":"SUCCESS"}
{"id":"4c26e3ee-cfdc-4b88-b865-4d161d53e518","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20297"},"specVersion":"0.1.0","time":"2024-04-09T23:09:51.555635718Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"6d955a5c-e6b9-4662-a684-29896a1ba8ec","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20298"},"specVersion":"0.1.0","time":"2024-04-09T23:09:52.489401969Z","eventData":"SUCCESS"}
{"id":"bafa0b9e-567f-4cc6-af7a-51977fd4d12e","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20298"},"specVersion":"0.1.0","time":"2024-04-09T23:09:52.496663677Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"a9e105ee-37f6-44f0-970f-50d493210cb1","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20299"},"specVersion":"0.1.0","time":"2024-04-09T23:09:53.429193761Z","eventData":"SUCCESS"}
{"id":"ef70be44-0307-49f4-8313-f04d73a3fdc1","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20299"},"specVersion":"0.1.0","time":"2024-04-09T23:09:53.446374053Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"0bcd4d8e-99e3-4610-b3c1-4c05fc9b0f6f","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20300"},"specVersion":"0.1.0","time":"2024-04-09T23:09:54.480242595Z","eventData":"SUCCESS"}
{"id":"22ce63b6-f0bb-4432-af4e-35c0ff22d039","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20300"},"specVersion":"0.1.0","time":"2024-04-09T23:09:54.483664678Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"ba9c926c-14f5-4eed-ad8e-242c132b26a4","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20301"},"specVersion":"0.1.0","time":"2024-04-09T23:09:55.520595720Z","eventData":"SUCCESS"}
{"id":"8ee65270-8ed1-4b35-99b6-5aea6d694951","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20301"},"specVersion":"0.1.0","time":"2024-04-09T23:09:55.526192179Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"d01ba5e6-7e74-4f01-9a03-0aca458892f8","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20302"},"specVersion":"0.1.0","time":"2024-04-09T23:09:56.463703179Z","eventData":"SUCCESS"}
{"id":"5774d914-74ab-4a7a-ab01-8d3c115f18fc","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20302"},"specVersion":"0.1.0","time":"2024-04-09T23:09:56.468913346Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"424f1ac2-593d-4185-b604-924e01571161","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20303"},"specVersion":"0.1.0","time":"2024-04-09T23:09:57.399816554Z","eventData":"SUCCESS"}
{"id":"bd283708-71b4-433b-a0c4-9bd2501e426c","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20303"},"specVersion":"0.1.0","time":"2024-04-09T23:09:57.402670096Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"21a5fd43-d723-42f4-9456-ee34ad5d36d5","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20328"},"specVersion":"0.1.0","time":"2024-04-09T23:09:58.436008972Z","eventData":"SUCCESS"}
{"id":"1cab81b7-2320-41a9-866c-8ab75f5b476a","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20328"},"specVersion":"0.1.0","time":"2024-04-09T23:09:58.439589680Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"262dc105-affe-4919-a0e6-27c4006a9375","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20329"},"specVersion":"0.1.0","time":"2024-04-09T23:09:59.475524930Z","eventData":"SUCCESS"}
{"id":"33086e6c-73ee-463c-976e-64feb810174c","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20329"},"specVersion":"0.1.0","time":"2024-04-09T23:09:59.483149722Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"c22fbaef-3097-45b3-b0c0-e3c21943ae48","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20330"},"specVersion":"0.1.0","time":"2024-04-09T23:10:00.530822542Z","eventData":"SUCCESS"}
{"id":"4ba878bb-fa90-452e-8591-e8c209e0be8b","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20330"},"specVersion":"0.1.0","time":"2024-04-09T23:10:00.546296167Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"b33323a6-357a-48b6-8eba-70ccdbd83576","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20331"},"specVersion":"0.1.0","time":"2024-04-09T23:10:01.373270167Z","eventData":"SUCCESS"}
{"id":"c5e5333a-804c-4453-b5c7-7f654f5730eb","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20331"},"specVersion":"0.1.0","time":"2024-04-09T23:10:01.375501125Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"48839639-7216-4321-abbe-be2922a84c4a","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20332"},"specVersion":"0.1.0","time":"2024-04-09T23:10:02.404853293Z","eventData":"SUCCESS"}
{"id":"9f49e892-c518-489e-86c4-54eb5dfc904b","source":"krn://cluster=gMNHV-4RQaKxsx3YNGWhIg","type":"SAFEGUARD","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":null,"remoteAddress":"/192.168.65.1:20332"},"specVersion":"0.1.0","time":"2024-04-09T23:10:02.407692834Z","eventData":{"level":"error","plugin":"io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin","message":"clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"}}
{"id":"a2200bda-a3e5-4c15-bda2-a38c2e9eb584","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6969","remoteAddress":"/192.168.65.1:20333"},"specVersion":"0.1.0","time":"2024-04-09T23:10:03.714217668Z","eventData":"SUCCESS"}
{"id":"7c1d1677-b322-4534-bfff-7073b2d6661b","source":null,"type":"AUTHENTICATION","authenticationPrincipal":"teamA","userName":"sa","connection":{"localAddress":"/172.23.0.8:6970","remoteAddress":"/192.168.65.1:36224"},"specVersion":"0.1.0","time":"2024-04-09T23:10:03.743503252Z","eventData":"SUCCESS"}
[2024-04-10 03:10:08,231] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 135 messages

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/mf6VjPQPqtFTsm5GdUSQSME0J.svg)](https://asciinema.org/a/mf6VjPQPqtFTsm5GdUSQSME0J)

</details>

## Tearing down the docker environment

Remove all your docker processes and associated volumes

* `--volumes`: Remove named volumes declared in the "volumes" section of the Compose file and anonymous volumes attached to containers.

<details open>
<summary>Command</summary>



```sh
docker compose down --volumes
```



</details>
<details>
<summary>Output</summary>

```
 Container gateway1  Stopping
 Container gateway2  Stopping
 Container schema-registry  Stopping
 Container kafka-client  Stopping
 Container gateway1  Stopped
 Container gateway1  Removing
 Container gateway1  Removed
 Container gateway2  Stopped
 Container gateway2  Removing
 Container gateway2  Removed
 Container schema-registry  Stopped
 Container schema-registry  Removing
 Container schema-registry  Removed
 Container kafka1  Stopping
 Container kafka3  Stopping
 Container kafka2  Stopping
 Container kafka2  Stopped
 Container kafka2  Removing
 Container kafka2  Removed
 Container kafka3  Stopped
 Container kafka3  Removing
 Container kafka3  Removed
 Container kafka-client  Stopped
 Container kafka-client  Removing
 Container kafka-client  Removed
 Container kafka1  Stopped
 Container kafka1  Removing
 Container kafka1  Removed
 Container zookeeper  Stopping
 Container zookeeper  Stopped
 Container zookeeper  Removing
 Container zookeeper  Removed
 Network safeguard-client-id_default  Removing
 Network safeguard-client-id_default  Removed

```

</details>
<details>
<summary>Recording</summary>

[![asciicast](https://asciinema.org/a/2sjEvgo6eo9eqWOw8PZPfSR73.svg)](https://asciinema.org/a/2sjEvgo6eo9eqWOw8PZPfSR73)

</details>

# Conclusion

You can now make sure you have valid client id to help the right customers

