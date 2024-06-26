#!/bin/bash
# Generate virtual cluster aclCluster with service account consumer
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/aclCluster/username/consumer" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

# Create access file
echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='consumer' password='$token';
""" > aclCluster-consumer.properties

# Review file
cat aclCluster-consumer.properties
