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


header 'Header Injection'
execute "step-04-DOCKER.sh" "Startup the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTERS.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`users\`"
execute "step-08-ADD_INTERCEPTORS.sh" "Adding interceptor \`inject-headers\` in \`gateway1\`"
execute "step-09-PRODUCE.sh" "Send tom and florent into \`users\`"
execute "step-10-CONSUME.sh" "Verify tom and florent have the corresponding headers"
execute "step-11-ADD_INTERCEPTORS.sh" "Adding interceptor \`remove-headers\` in \`gateway1\`"
execute "step-12-CONSUME.sh" "Verify tom and florent have the corresponding headers"
execute "step-13-REMOVE_INTERCEPTORS.sh" "Remove interceptor \`remove-headers\`"
execute "step-14-CONSUME.sh" "Verify \`tom\` and \`florent\` have \`X-MY-KEY\` back"
execute "step-15-DOCKER.sh" "Cleanup the docker environment"
