kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --replication-factor 1 \
    --partitions 5 \
    --create --if-not-exists \
    --topic hold-many-concentrated-topics
