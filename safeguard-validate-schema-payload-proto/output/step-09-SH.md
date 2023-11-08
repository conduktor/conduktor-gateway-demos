
<details>
<summary>Command output</summary>

```sh

curl -s \
  http://localhost:8081/subjects/topic-protobuf/versions \
  -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data "{\"schemaType\": \"PROTOBUF\", \"schema\": $(cat user-schema.proto | jq -Rs)}"
cat user-schema.proto | jq -Rs
{"id":1}
```

</details>
      
