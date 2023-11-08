
<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
Created topic cars.

```

</details>
      
