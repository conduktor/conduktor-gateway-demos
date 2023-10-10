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

execute """echo \"CREATE STREAM IF NOT EXISTS \
                ratings (name VARCHAR, rating INTEGER) \
                WITH (kafka_topic='topic-test', value_format='json', partitions=4, replicas=1);\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"CREATE TABLE IF NOT EXISTS \
                currentRating AS SELECT name, LATEST_BY_OFFSET(rating) AS rating \
                FROM ratings GROUP BY name EMIT CHANGES;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"INSERT INTO ratings (name, rating) VALUES ('name 1', 1);\
                  INSERT INTO ratings (name, rating) VALUES ('name 1', 5);\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM currentRating;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""

execute """echo \"SELECT * FROM ratings;\" | \\
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
"""