#!/bin/bash
export KSQL_BOOTSTRAP_SERVERS="localhost:6969"
export KSQL_SECURITY_PROTOCOL="SASL_PLAINTEXT"
export KSQL_SASL_MECHANISM="PLAIN"
export KSQL_SASL_JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username='sa' password='eyJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InNhIiwidmNsdXN0ZXIiOiJ0ZWFtQSIsImV4cCI6MTcyMDQ3NjcyN30.uXvT0BY3s6tYFRD6pPoSwVJXZl034ere0K9nkbIBi4Y';"
docker compose --profile ksqldb up -d --wait