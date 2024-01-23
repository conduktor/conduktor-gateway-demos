#!/bin/sh

. utils.sh

header 'Cluster Switching'
execute "step-07-DOCKER.sh" "Starting the docker environment"
execute "step-08-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-10-CREATE_TOPICS.sh" "Creating topic \`users\` on \`teamA\`"
execute "step-11-PRODUCE.sh" "Send \`tom\` and \`florent\` into topic \`users\`"
execute "step-12-LIST_TOPICS.sh" "Listing topics in \`kafka1\`"
execute "step-13-CONSUME.sh" "Wait for mirror maker to do its job on gateway internal topic"
execute "step-14-CONSUME.sh" "Wait for mirror maker to do its job on \`users\` topics"
execute "step-15-LIST_TOPICS.sh" "Assert mirror maker did its job"
execute "step-16-FAILOVER.sh" "Failing over from \`main\` to \`failover\`"
execute "step-17-FAILOVER.sh" "Failing over from \`main\` to \`failover\`"
execute "step-18-PRODUCE.sh" "Produce \`thibault\` into \`users\`, it should hit only \`failover-kafka\`"
execute "step-19-CONSUME.sh" "Verify we can read \`florent\` (via mirror maker), \`tom\` (via mirror maker) and \`thibault\` (via cluster switching)"
execute "step-20-CONSUME.sh" "Verify \`thibaut\` is not in main kafka"
execute "step-21-CONSUME.sh" "Verify \`thibaut\` is in failover"
execute "step-22-DOCKER.sh" "Tearing down the docker environment"
