
<details>
<summary>Command output</summary>

```sh

export KSQL_BOOTSTRAP_SERVERS="localhost:6969"
export KSQL_SECURITY_PROTOCOL="SASL_PLAINTEXT"
export KSQL_SASL_MECHANISM="PLAIN"
export KSQL_SASL_JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzczODk5NX0.WHXG_DPBRBce90-s8vIy4E6fnMNHzk1ERbAVD3qpxaA';"
docker compose --profile ksqldb up -d --wait
 Container zookeeper  Running
 Container kafka1  Running
 Container kafka2  Running
 Container kafka3  Running
 Container schema-registry  Running
 Container gateway2  Running
 Container ksqldb-server  Creating
 Container gateway1  Running
 ksqldb-server Published ports are discarded when using host network mode 
 Container ksqldb-server  Created
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container zookeeper  Healthy
 Container zookeeper  Healthy
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container ksqldb-server  Starting
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container ksqldb-server  Started
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container schema-registry  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container ksqldb-server  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container gateway1  Healthy
 Container kafka3  Healthy
 Container gateway2  Healthy
 Container schema-registry  Healthy
 Container ksqldb-server  Healthy

```

</details>
      
