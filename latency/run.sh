#!/bin/bash

. utils.sh

header 'Latency'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_TOPICS.sh" "Creating topic physical-kafka on kafka1"
execute "step-06-SH.sh" "Let's use EndToEndLatency that comes bundled with Kafka"
execute "step-07-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-08-CREATE_TOPICS.sh" "Creating topic via-gateway on teamA"
execute "step-09-SH.sh" "Let's use kafka-producer-perf-test that comes bundled with Kafka"
execute "step-10-DOCKER.sh" "Tearing down the docker environment"
