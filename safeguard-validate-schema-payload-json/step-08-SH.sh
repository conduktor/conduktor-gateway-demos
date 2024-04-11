#!/bin/bash
curl -s \
  http://localhost:8081/subjects/topic-json-schema/versions \
  -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data "{\"schemaType\": \"JSON\", \"schema\": $(cat user-schema-with-validation-rules.json | jq tostring)}"