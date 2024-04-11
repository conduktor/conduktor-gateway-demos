#!/bin/bash
kafka-acls \
    --bootstrap-server localhost:6969 \
    --command-config aclCluster-admin.properties \
    --add \
    --allow-principal User:consumer \
    --operation read \
    --topic restricted-topic