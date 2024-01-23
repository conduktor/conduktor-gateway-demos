
<details>
<summary>Command output</summary>

```sh

echo '{"msg":"hello world"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic concentrated-topic-with-100-partitions

```

</details>
      
