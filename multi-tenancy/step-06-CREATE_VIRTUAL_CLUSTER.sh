#!/bin/bash
# Generate virtual cluster london with service account sa
token=$(curl \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/london/username/sa" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

# Create access file
echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='$token';
""" > london-sa.properties

# Review file
cat london-sa.properties
