
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 10000 \
 | jq
Processed a total of 1 messages
{
  "type": "Sports",
  "price": 1000,
  "color": "red"
}

```

</details>
      
