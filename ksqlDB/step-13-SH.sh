#!/bin/bash
docker exec ksqldb-server ksql 'http://localhost:8088' -f /sql/ksql.sql