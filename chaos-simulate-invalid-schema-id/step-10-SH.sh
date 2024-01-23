echo '{"message": "hello world"}' | \
  kafka-json-schema-console-producer \
  --bootstrap-server localhost:6969 \
  --topic with-schema \
  --producer.config teamA-sa.properties \
  --property value.schema='{
  "title": "someSchema",
  "type": "object",
  "properties": {
    "message": {
      "type": "string"
    }
  }
}'