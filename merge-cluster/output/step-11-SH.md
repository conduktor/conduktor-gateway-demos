
<details>
<summary>Command output</summary>

```sh

curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/topicMappings/teamA/us_cars \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "clusterId": "cluster1",
      "topicName": "cars",
      "concentrated": false
    }' | jq
{
  "message": "cars is created"
}

curl \
  --silent \
  --user admin:conduktor \
  --request POST localhost:8888/topics/teamA \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "name": "us_cars"
    }' | jq
{
  "message": "us_cars is created"
}

```

</details>
      
