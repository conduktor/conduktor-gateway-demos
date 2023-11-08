
<details>
<summary>Command output</summary>

```sh

echo '{"message: "Hello from London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
        --topic existingLondonTopic

```

</details>
      
