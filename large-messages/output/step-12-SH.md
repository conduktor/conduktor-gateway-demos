
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer  \
  --bootstrap-server localhost:6969 \
  --consumer.config teamA-sa.properties \
  --topic large-messages \
  --from-beginning \
  --property print.headers=true \
  --max-messages 1 > from-kafka.bin
Processed a total of 1 messages

```

</details>
      
