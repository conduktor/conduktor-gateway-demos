#!/bin/bash
echo '{"message: "Bonjour depuis Paris"}' | \
    kafka-console-producer \
        --bootstrap-server localhost:6969 \
        --producer.config paris-sa.properties \
        --topic parisTopic