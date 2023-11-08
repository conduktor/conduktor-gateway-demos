
<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-consumer.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic restricted-topic
Error while executing topic command : Cluster not authorized
[2024-01-22 17:24:00,729] ERROR org.apache.kafka.common.errors.ClusterAuthorizationException: Cluster not authorized
 (kafka.admin.TopicCommand$)

```

</details>
      
