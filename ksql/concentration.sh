#!/bin/bash

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

#execute """docker compose up --wait --detach"""
#
execute """docker compose exec kafka-client \\
  kafka-topics \\
    --bootstrap-server kafka1:9092 \\
    --create --if-not-exists \\
    --topic real-topic \\
    --replication-factor 1 \\
    --partitions 10
"""

execute """docker compose exec kafka-client \\
  curl \\
    --silent \\
    --user \"admin:conduktor\" \\
    --request POST 'conduktor-gateway:8888/admin/vclusters/v1/vcluster/london/topics/.%2A' \\
    --header \"Content-Type: application/json\" \\
    --data-raw '{
        \"physicalTopicName\": \"real-topic\",
        \"readOnly\": false,
        \"concentrated\": true
    }'
"""

execute """echo \"CREATE STREAM IF NOT EXISTS \
                filmRatings (name VARCHAR, rating INTEGER) \
                WITH (kafka_topic='topic-a', value_format='json', partitions=4, replicas=1);\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"CREATE STREAM IF NOT EXISTS \
                filmComments (name VARCHAR, comment VARCHAR) \
                WITH (kafka_topic='topic-a', value_format='json', partitions=4, replicas=1);\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"CREATE STREAM IF NOT EXISTS \
                restaurantRatings (name VARCHAR, rating INTEGER) \
                WITH (kafka_topic='topic-b', value_format='json', partitions=4, replicas=1);\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"CREATE STREAM IF NOT EXISTS \
                restaurantComments (name VARCHAR, comment VARCHAR) \
                WITH (kafka_topic='topic-b', value_format='json', partitions=4, replicas=1);\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""
#
#execute """echo \"CREATE TABLE IF NOT EXISTS \
#                currentRating AS SELECT name, LATEST_BY_OFFSET(rating) AS rating \
#                FROM ratings GROUP BY name EMIT CHANGES;\" | \\
#  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
#"""
#
execute """echo \"INSERT INTO filmRatings (name, rating) VALUES ('film 1', 1);\
                  INSERT INTO filmRatings (name, rating) VALUES ('film 1', 5);\
                  INSERT INTO filmComments (name, comment) VALUES ('film 1', 'comment film 1');\
                  INSERT INTO filmComments (name, comment) VALUES ('film 1', 'comment film 2');\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"INSERT INTO restaurantRatings (name, rating) VALUES ('restaurant 1', 1);\
                  INSERT INTO restaurantRatings (name, rating) VALUES ('restaurant 1', 5);\
                  INSERT INTO restaurantComments (name, comment) VALUES ('restaurant 1', 'restaurant film 1');\
                  INSERT INTO restaurantComments (name, comment) VALUES ('restaurant 1', 'restaurant film 2');\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM filmRatings;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM filmComments;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM restaurantRatings;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM restaurantComments;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""