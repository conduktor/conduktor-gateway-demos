
<details>
<summary>Command output</summary>

```sh

cat step-06-mapping.json | jq
{
  "concentrated": true,
  "readOnly": false,
  "physicalTopicName": "concentrated"
}

curl \
    --request POST 'http://localhost:8888/admin/vclusters/v1/vcluster/teamA/topics/.%2A' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data "@step-06-mapping.json" | jq
{
  "logicalTopicName": ".*",
  "physicalTopicName": "concentrated",
  "readOnly": false,
  "concentrated": true
}

```

</details>
      
