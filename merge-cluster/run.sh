#!/bin/bash

. utils.sh

header 'Merge Cluster'
execute "step-05-DOCKER.sh" "Starting the docker environment"
execute "step-06-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-07-CREATE_TOPICS.sh" "Create the topic 'cars' in main cluster"
execute "step-08-CREATE_TOPICS.sh" "Create the topic 'cars' in cluster1"
execute "step-09-SH.sh" "Let's route the topic 'eu_cars', as seen by the client application, on to the 'cars' topic on the main (default) cluster"
execute "step-10-SH.sh" "Let's route the topic 'us_cars', as seen by the client application, on to the 'cars' topic on the second cluster (cluster1)"
execute "step-11-PRODUCE.sh" "Send into topic 'eu_cars'"
execute "step-12-PRODUCE.sh" "Send into topic 'us_cars'"
execute "step-13-CONSUME.sh" "Consuming from eu_cars"
execute "step-14-CONSUME.sh" "Consuming from us_cars"
execute "step-15-CONSUME.sh" "Verify eu_cars_record is not in main kafka"
execute "step-16-CONSUME.sh" "Verify us_cars_record is not in cluster1 kafka"
execute "step-17-DOCKER.sh" "Tearing down the docker environment"
