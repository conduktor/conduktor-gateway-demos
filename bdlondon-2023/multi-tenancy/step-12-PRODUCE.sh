echo '{"message: "Hello from London"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config london-sa.properties \
        --topic londonTopic