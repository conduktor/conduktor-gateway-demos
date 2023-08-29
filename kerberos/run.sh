#!/bin/sh
function execute() {
    chars=$(echo "$*" | wc -c)
    sleep 2
    printf "$"
    if [ "$chars" -lt 100 ] ; then
        echo "$*" | pv -qL 50
    elif [ "$chars" -lt 250 ] ; then
        echo "$*" | pv -qL 100
    elif [ "$chars" -lt 500 ] ; then
        echo "$*" | pv -qL 200
    else
        echo "$*" | pv -qL 400
    fi
    eval "$*"
}

execute """./start.sh
"""

execute """password=$(docker compose exec gateway \\
curl \\
--user \"admin:conduktor\" \\
--request POST gateway:8888/admin/vclusters/v1/vcluster/someCluster/username/someUsername \\
--header \"content-type:application/json\" \\
--data-raw '{\"lifeTimeSeconds\":7776000}' | jq -r .token)
"""

execute """echo  \"\"\"
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"someUsername\" password=\"$password\";
\"\"\" > security/someUsername-jwt.properties
"""

execute """docker compose exec cli-kafka \\
  kafka-topics \\
    --bootstrap-server gateway:6969 \\
    --command-config /etc/kafka/secrets/someUsername-jwt.properties \\
    --create --if-not-exists \\
    --topic my-topic
"""

execute """docker compose exec cli-kafka \\
  kafka-topics \\
    --bootstrap-server gateway:6969 \\
    --command-config /etc/kafka/secrets/someUsername-jwt.properties \\
    --list
"""

execute """echo '{\"message\":\"hello world\"}' | \\
  docker compose exec -T cli-kafka \\
    kafka-console-producer \\
      --bootstrap-server gateway:6969 \\
      --producer.config /etc/kafka/secrets/someUsername-jwt.properties \\
      --topic my-topic
"""

execute """docker compose exec cli-kafka \\
  kafka-console-consumer \\
    --bootstrap-server gateway:6969 \\
    --consumer.config /etc/kafka/secrets/someUsername-jwt.properties \\
    --topic my-topic \\
    --from-beginning \\
    --max-messages 1 | jq
"""

execute """./stop.sh
"""

