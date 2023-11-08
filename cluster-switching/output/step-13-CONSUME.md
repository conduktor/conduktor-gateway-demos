
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic _topicMappings \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 15000 \
 | jq
Processed a total of 1 messages
{
  "users": {
    "clusterId": "main",
    "name": "teamAusers",
    "isConcentrated": false,
    "compactedName": "teamAusers",
    "isCompacted": false,
    "compactedAndDeletedName": "teamAusers",
    "isCompactedAndDeleted": false,
    "createdAt": [
      2024,
      1,
      22,
      17,
      24,
      8,
      672
    ],
    "isDeleted": false,
    "configuration": {
      "numPartitions": 1,
      "replicationFactor": 1,
      "properties": {}
    },
    "isVirtual": false
  }
}

```

</details>
      
