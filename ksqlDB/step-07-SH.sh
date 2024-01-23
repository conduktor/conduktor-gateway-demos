export KSQL_BOOTSTRAP_SERVERS="localhost:6969"
export KSQL_SECURITY_PROTOCOL="SASL_PLAINTEXT"
export KSQL_SASL_MECHANISM="PLAIN"
export KSQL_SASL_JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcxMzczODk5NX0.WHXG_DPBRBce90-s8vIy4E6fnMNHzk1ERbAVD3qpxaA';"
docker compose --profile ksqldb up -d --wait