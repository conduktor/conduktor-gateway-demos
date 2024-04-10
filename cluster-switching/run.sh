#!/bin/bash

. utils.sh

header 'Cluster Switching / Failover'
execute "step-07-DOCKER.sh" "Starting the docker environment"
execute "step-08-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-09-CREATE_TOPICS.sh" "Creating topic users on teamA"
execute "step-10-PRODUCE.sh" "Send tom and laura into topic users"
execute "step-11-LIST_TOPICS.sh" "Listing topics in kafka1"
execute "step-12-CONSUME.sh" "Wait for mirror maker to do its job on gateway internal topic"
execute "step-13-CONSUME.sh" "Wait for mirror maker to do its job on users topics"
execute "step-14-LIST_TOPICS.sh" "Assert mirror maker did its job"
execute "step-15-FAILOVER.sh" "Failing over from main to failover"
execute "step-16-FAILOVER.sh" "Failing over from main to failover"
execute "step-17-PRODUCE.sh" "Produce alice into users, it should hit only failover-kafka"
execute "step-18-CONSUME.sh" "Verify we can read laura (via mirror maker), tom (via mirror maker) and alice (via cluster switching)"
execute "step-19-CONSUME.sh" "Verify alice is not in main kafka"
execute "step-20-CONSUME.sh" "Verify alice is in failover"
execute "step-21-DOCKER.sh" "Tearing down the docker environment"
