echo '{"type": "Sports", "price": 75, "color": "blue"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config teamA-sa.properties \
        --topic concentrated-topic-with-10-partitions