
<details>
<summary>Command output</summary>

```sh

curl \
  --silent \
  --request POST localhost:8888/admin/vclusters/v1/vcluster/london/topics/existingSharedTopic \
  --user admin:conduktor \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "physicalTopicName": "existingSharedTopic",
    "readOnly": false,
    "concentrated": false
  }' | jq
{
  "logicalTopicName": "existingSharedTopic",
  "physicalTopicName": "existingSharedTopic",
  "readOnly": false,
  "concentrated": false
}

```

</details>
      
