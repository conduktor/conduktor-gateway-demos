
<details>
<summary>Command output</summary>

```sh

curl -s \
  http://localhost:8081/subjects/topic-avro/versions \
  -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data "{\"schemaType\": \"AVRO\", \"schema\": $(cat user-schema.avsc | jq tostring)}"
cat user-schema.avsc | jq tostring
{"id":1}
```

</details>
      
