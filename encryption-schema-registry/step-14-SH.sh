kafka-json-schema-console-consumer \
  --bootstrap-server localhost:6969 \
  --consumer.config teamA-sa.properties \
  --property schema.registry.url=http://localhost:8081 \
  --topic customers \
  --from-beginning \
  --max-messages 2 2>&1 | grep '{' | jq