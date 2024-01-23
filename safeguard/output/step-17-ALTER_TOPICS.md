
<details>
<summary>Command output</summary>

```sh

kafka-configs \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --alter \
    --entity-type topics \
    --entity-name roads \
    --add-config retention.ms=259200000
Completed updating config for topic roads.

```

</details>
      
