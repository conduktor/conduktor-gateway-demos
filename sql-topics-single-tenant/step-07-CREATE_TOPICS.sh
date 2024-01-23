kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config passthrough-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic cars
