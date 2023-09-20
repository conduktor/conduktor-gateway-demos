kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --add-config retention.ms=259200000 \
    --alter \
    --topic roads
