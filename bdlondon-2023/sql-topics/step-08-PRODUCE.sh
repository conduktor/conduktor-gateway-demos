echo '{"type":"Sports","price":75,"color":"blue"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars

echo '{"type":"SUV","price":55,"color":"red"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic cars