
<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-admin.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic restricted-topic
Created topic restricted-topic.

```

</details>
      
