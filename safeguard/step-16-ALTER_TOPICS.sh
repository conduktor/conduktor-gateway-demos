kafka-configs \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --alter \
    --entity-type topics \
    --entity-name roads \
    --add-config retention.ms=5184000000
