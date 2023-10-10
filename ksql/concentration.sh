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
    --request POST 'conduktor-gateway:8888/admin/vclusters/v1/vcluster/london/topics/topic.%2A' \\
    --header \"Content-Type: application/json\" \\
    --data-raw '{
        \"physicalTopicName\": \"real-topic\",
        \"readOnly\": false,
        \"concentrated\": true
    }'
"""
echo ""

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

execute """echo \"CREATE TABLE IF NOT EXISTS \
                currentFilmRating AS SELECT name, LATEST_BY_OFFSET(rating) AS rating \
                FROM filmRatings GROUP BY name EMIT CHANGES;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"CREATE TABLE IF NOT EXISTS \
                currentRestaurantRating AS SELECT name, LATEST_BY_OFFSET(rating) AS rating \
                FROM restaurantRatings GROUP BY name EMIT CHANGES;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"INSERT INTO filmRatings (name, rating) VALUES ('film 1', 1);\
                  INSERT INTO filmRatings (name, rating) VALUES ('film 1', 5);\
                  INSERT INTO filmComments (name, comment) VALUES ('film 1', 'comment 1');\
                  INSERT INTO filmComments (name, comment) VALUES ('film 1', 'comment 2');
                  INSERT INTO restaurantRatings (name, rating) VALUES ('restaurant 1', 3);\
                  INSERT INTO restaurantRatings (name, rating) VALUES ('restaurant 1', 5);\
                  INSERT INTO restaurantComments (name, comment) VALUES ('restaurant 1', 'comment 1');\
                  INSERT INTO restaurantComments (name, comment) VALUES ('restaurant 1', 'comment 2');\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM filmRatings LIMIT 4;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM filmComments LIMIT 4;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM restaurantRatings LIMIT 4;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM restaurantComments LIMIT 4;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM currentFilmRating;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM currentRestaurantRating;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""