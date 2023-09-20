kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --create --if-not-exists \
    --topic concentrated-normal
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config cleanup.policy=delete \
    --create --if-not-exists \
    --topic concentrated-delete
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config cleanup.policy=compact \
    --create --if-not-exists \
    --topic concentrated-compact
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config cleanup.policy=delete,compact \
    --create --if-not-exists \
    --topic concentrated-delete-compact
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config cleanup.policy=compact,delete \
    --create --if-not-exists \
    --topic concentrated-compact-delete
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config retention.ms=10000 \
    --create --if-not-exists \
    --topic concentrated-small-retention
kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --replication-factor 1 \
    --partitions 1 \
    --config retention.ms=6048000000 \
    --create --if-not-exists \
    --topic concentrated-large-retention
