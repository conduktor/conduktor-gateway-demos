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


header 'Safeguard'
execute "step-04-DOCKER.sh" "Startup the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTERS.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`cars\`"
execute "step-08-PRODUCE.sh" "Producing 3messages in \`cars\`"
execute "step-09-CONSUME.sh" "Consume the \`cars\` topic"
execute "step-10-DESCRIBE_TOPICS.sh" "Describing topic \`cars\`"
execute "step-11-ADD_INTERCEPTORS.sh" "Adding interceptor \`guard-on-create-topic\` in \`gateway1\`"
execute "step-12-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-13-CREATE_TOPICS.sh" "Create a topic that is not within policy"
execute "step-14-CREATE_TOPICS.sh" "Let's now create it again, with parameters within our policy"
execute "step-15-ADD_INTERCEPTORS.sh" "Adding interceptor \`guard-on-alter-topic\` in \`gateway1\`"
execute "step-17-ALTER_TOPICS.sh" "Update 'cars' with a retention of 3 days"
execute "step-18-ADD_INTERCEPTORS.sh" "Adding interceptor \`guard-on-produce\` in \`gateway1\`"
execute "step-20-PRODUCE.sh" "Produce sample data to our \`cars\` topic that complies with our policy"
execute "step-21-DOCKER.sh" "Cleanup the docker environment"
