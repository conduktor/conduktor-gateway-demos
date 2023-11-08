
<details>
<summary>Command output</summary>

```sh

curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/admin/vclusters/v1/vcluster/london/topics/existingLondonTopic \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "physicalTopicName": "existingLondonTopic",
      "readOnly": false,
      "concentrated": false
    }' | jq
{
  "logicalTopicName": "existingLondonTopic",
  "physicalTopicName": "existingLondonTopic",
  "readOnly": false,
  "concentrated": false
}

```

</details>
      
