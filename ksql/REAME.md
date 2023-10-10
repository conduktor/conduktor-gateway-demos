# Conduktor KSQL Demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A KsqlDB server
* 2 node Kafka cluster
* A single Conduktor Gateway container
* A Kafka Client container (this provides nothing more than a place to run kafka client commands)
* A KsqlDB CLI container (this provides nothing more than a place to run Ksql commands)

### Step 2: Start the environment

Start the environment with

```bash
docker compose up --wait --detach
```

### Step 3: KSql with topic un-concentration

Create a `ratings` stream
```bash
echo "CREATE STREAM IF NOT EXISTS \
                ratings (name VARCHAR, rating INTEGER) \
                WITH (kafka_topic='topic-test', value_format='json', partitions=4, replicas=1);" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Create a `currentRating` table

```bash
echo "CREATE TABLE IF NOT EXISTS \
                currentRating AS SELECT name, LATEST_BY_OFFSET(rating) AS rating \
                FROM ratings GROUP BY name EMIT CHANGES;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Insert data into streams and tables
```bash
echo "INSERT INTO ratings (name, rating) VALUES ('name 1', 1);\
       INSERT INTO ratings (name, rating) VALUES ('name 1', 5);
       INSERT INTO ratings (name, rating) VALUES ('name 2', 4);
       INSERT INTO ratings (name, rating) VALUES ('name 2', 2);" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Now, select data from `ratings` stream
```bash
echo "SELECT * FROM currentRating;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

And, select data from `currentRating` table
```bash
echo "SELECT * FROM ratings;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

### Step 4: Ksql with topic concentration

Create a real topic
```bash
docker compose exec kafka-client \
  kafka-topics \
    --bootstrap-server kafka1:9092 \
    --create --if-not-exists \
    --topic real-topic \
    --replication-factor 1 \
    --partitions 10
```

Create a topic mapping that maps to the `real-topic`
```bash
docker compose exec kafka-client \
  curl \
    --silent \
    --user \"admin:conduktor\" \
    --request POST 'conduktor-gateway:8888/admin/vclusters/v1/vcluster/london/topics/topic.%2A' \
    --header \"Content-Type: application/json\" \
    --data-raw '{
        \"physicalTopicName\": \"real-topic\",
        \"readOnly\": false,
        \"concentrated\": true
    }'
```

Create a `filmRatings` stream 
```bash
echo "CREATE STREAM IF NOT EXISTS \
                filmRatings (name VARCHAR, rating INTEGER) \
                WITH (kafka_topic='topic-a', value_format='json', partitions=4, replicas=1);" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Create a `filmComments` stream
```bash
echo "CREATE STREAM IF NOT EXISTS \
                filmComments (name VARCHAR, comment VARCHAR) \
                WITH (kafka_topic='topic-a', value_format='json', partitions=4, replicas=1);" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Create a `restaurantRatings` stream
```bash
echo "CREATE STREAM IF NOT EXISTS \
                restaurantRatings (name VARCHAR, rating INTEGER) \
                WITH (kafka_topic='topic-b', value_format='json', partitions=4, replicas=1);" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Create a `restaurantComments` stream
```bash
echo "CREATE STREAM IF NOT EXISTS \
                restaurantComments (name VARCHAR, comment VARCHAR) \
                WITH (kafka_topic='topic-b', value_format='json', partitions=4, replicas=1);" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Create a `currentFilmRating` table
```bash
echo "CREATE TABLE IF NOT EXISTS \
                currentFilmRating AS SELECT name, LATEST_BY_OFFSET(rating) AS rating \
                FROM filmRatings GROUP BY name EMIT CHANGES;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Create a `currentRestaurantRating` table
```bash
echo "CREATE TABLE IF NOT EXISTS \
                currentRestaurantRating AS SELECT name, LATEST_BY_OFFSET(rating) AS rating \
                FROM restaurantRatings GROUP BY name EMIT CHANGES;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Insert data into streams and tables
```bash
echo "INSERT INTO filmRatings (name, rating) VALUES ('film 1', 1);\
                  INSERT INTO filmRatings (name, rating) VALUES ('film 1', 5);\
                  INSERT INTO filmComments (name, comment) VALUES ('film 1', 'comment 1');\
                  INSERT INTO filmComments (name, comment) VALUES ('film 1', 'comment 2');
                  INSERT INTO restaurantRatings (name, rating) VALUES ('restaurant 1', 3);\
                  INSERT INTO restaurantRatings (name, rating) VALUES ('restaurant 1', 5);\
                  INSERT INTO restaurantComments (name, comment) VALUES ('restaurant 1', 'comment 1');\
                  INSERT INTO restaurantComments (name, comment) VALUES ('restaurant 1', 'comment 2');" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Select data from `filmRatings`
```bash
echo "SELECT * FROM filmRatings;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Select data from `filmRatings`
```bash
echo "SELECT * FROM filmComments;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Select data from `restaurantRatings`
```bash
echo "SELECT * FROM restaurantRatings;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Select data from `restaurantComments`
```bash
echo "SELECT * FROM restaurantComments;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Select data from `currentFilmRating`
```bash
echo "SELECT * FROM currentFilmRating;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

Select data from `currentRestaurantRating`
```bash
echo "SELECT * FROM currentRestaurantRating;" | \
  docker exec -i ksqldb-cli ksql http://ksqldb-server:8088
```

### Step 5: Tear down

Run
```bash
docker compose down --volumes
```