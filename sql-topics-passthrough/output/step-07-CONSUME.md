
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --topic cars \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
 | jq
Processed a total of 2 messages
{
  "type": "Sports",
  "price": 75,
  "color": "blue"
}
{
  "type": "SUV",
  "price": 55,
  "color": "red"
}

```

</details>
      
