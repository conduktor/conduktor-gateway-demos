#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
WHITE='\033[0;97m'
NC='\033[0m' # No Color

function banner() {
    printf "$1# $2$NC\n" | pv -qL 20
}

function header() {
    banner "$RED" "$1"
}

function step() {
    banner "$BLUE" "$1"
}

function execute() {
    local script=$1
    local title=$2
    step "$title"
    sh type.sh "$script"
    echo
}


header 'Cluster Switching'
execute "step-07-DOCKER.sh" "Startup the docker environment"
execute "step-08-CREATE_VIRTUAL_CLUSTERS.sh" "Creating virtual cluster \`teamA\`"
execute "step-10-CREATE_TOPICS.sh" "Creating topic \`users\`"
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
execute "step-22-DOCKER.sh" "Cleanup the docker environment"
