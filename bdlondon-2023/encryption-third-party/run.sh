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


header 'Encryption for third party'
execute "step-04-DOCKER.sh" "Startup the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTERS.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_VIRTUAL_CLUSTERS.sh" "Let's create a service account \`third-party\` for \`teamA\` virtual cluster"
execute "step-08-CREATE_TOPICS.sh" "Creating topic \`customers\`"
execute "step-09-ADD_INTERCEPTORS.sh" "Adding interceptor \`encrypt-on-consume\` in \`gateway1\`"
execute "step-10-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-11-PRODUCE.sh" "Let's send unencrypted json"
execute "step-12-CONSUME.sh" "Confirm \`tom\` and \`florent\` data is not encrypted for \`teamA\`"
execute "step-13-CONSUME.sh" "Confirm \`tom\` and \`florent\` data is encrypted for \`third-party\`"
execute "step-14-DOCKER.sh" "Cleanup the docker environment"
