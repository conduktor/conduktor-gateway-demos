#!/bin/bash
# Generate virtual cluster aclCluster with service account admin
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/aclCluster/username/admin" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

# Create access file
echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='admin' password='$token';
""" > aclCluster-admin.properties

# Review file
cat aclCluster-admin.properties
