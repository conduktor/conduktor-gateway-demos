echo jsonSchemaId = $(curl -s -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
--data "{\"schemaType\": \"JSON\", \"schema\": $(cat user-schema.json | jq tostring)}" \
  http://localhost:8081/subjects/topic-json/versions)

echo avroSchemaId = $(curl -s -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
--data "{\"schemaType\": \"AVRO\", \"schema\": $(cat user-schema.avsc | jq tostring)}" \
  http://localhost:8081/subjects/topic-avro/versions)

echo protobufSchemaId = $(curl -s -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
--data "{\"schemaType\": \"PROTOBUF\", \"schema\": $(cat user-schema.proto | jq -Rs .)}" \
  http://localhost:8081/subjects/topic-protobuf/versions)