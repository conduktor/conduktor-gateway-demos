echo '{"message": "Existing shared message"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
        --topic existingSharedTopic