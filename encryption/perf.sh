#!/bin/sh

set -v

docker-compose exec kafka-client \
    kafka-topics \
        --bootstrap-server conduktor-proxy:6969 \
        --command-config /clientConfig/proxy.properties \
        --create --if-not-exists \
        --topic encryption-performance

docker-compose exec kafka-client curl \
    --silent \
    --user "superUser:superUser" \
    --request POST "conduktor-proxy:8888/tenant/proxy/feature/encryption" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "config": {
            "topic": "encryption-performance",
            "fields": [ {
                "fieldName": "password",
                "keySecretId": "secret-key-password",
                "algorithm": {
                    "type": "TINK/AES_GCM",
                    "kms": "TINK/KMS_INMEM"
                }
            },
            {
                "fieldName": "visa",
                "keySecretId": "secret-key-visaNumber",
                "algorithm": {
                    "type": "TINK/AES_GCM",
                    "kms": "TINK/KMS_INMEM"
                }
            }]
        },
        "direction": "REQUEST",
        "apiKeys": "PRODUCE"
    }'

printf '{"name":"london","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}\n%.0s' {1..1000000} > customers.json

echo number of lines: `wc -l customers.json | awk '{print $1}'`

echo file size: `du -sh customers.json | awk '{print $1}'`

time docker compose exec -T kafka-client \
    kafka-console-producer \
        --bootstrap-server conduktor-proxy:6969 \
        --producer.config /clientConfig/proxy.properties \
        --topic encryption-performance < customers.json

docker-compose exec kafka-client \
    kafka-console-consumer \
        --bootstrap-server conduktor-proxy:6969 \
        --consumer.config /clientConfig/proxy.properties \
        --topic encryption-performance \
        --from-beginning \
        --max-messages 20 | jq

docker compose cp customers.json kafka-client:/home/appuser

docker compose exec kafka-client \
    kafka-producer-perf-test \
        --topic encryption-performance \
        --throughput -1 \
        --num-records 1000000 \
        --producer-props bootstrap.servers=conduktor-proxy:6969 \
        --producer.config /clientConfig/proxy.properties \
        --payload-file customers.json