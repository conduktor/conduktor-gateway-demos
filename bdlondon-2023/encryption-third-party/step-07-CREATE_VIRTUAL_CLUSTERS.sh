token=$(curl \
    --silent \
    --user 'admin:conduktor' \
    --request POST "http://localhost:8888/admin/vclusters/v1/vcluster/teamA/username/third-party" \
    --header 'Content-Type: application/json' \
    --data-raw '{"lifeTimeSeconds": 7776000}' | jq -r ".token")

echo  """
bootstrap.servers=localhost:6969
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='third-party' password='$token';
""" > teamA-third-party.properties
