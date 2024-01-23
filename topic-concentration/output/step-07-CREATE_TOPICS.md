
<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 5 \
    --create --if-not-exists \
    --topic hold-many-concentrated-topics
Created topic hold-many-concentrated-topics.

```

</details>
      
