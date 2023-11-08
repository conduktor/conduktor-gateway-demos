kafka-topics \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
