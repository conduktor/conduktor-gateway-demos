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


header 'Crypto Shredding with fips'
execute "step-04-DOCKER.sh" "Startup the docker environment"
execute "step-05-SH.sh" "Verify the security provider setup"
execute "step-06-SH.sh" "Verify the disabled algorithms"
execute "step-07-CREATE_VIRTUAL_CLUSTERS.sh" "Creating virtual cluster \`teamA\`"
execute "step-08-CREATE_TOPICS.sh" "Creating topic \`customers-shredding\`"
execute "step-09-LIST_TOPICS.sh" "Listing topics in \`teamA\`"
execute "step-10-ADD_INTERCEPTORS.sh" "Adding interceptor \`crypto-shredding-encrypt\` in \`gateway1\`"
execute "step-11-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-12-PRODUCE.sh" "Let's produce sample data for \`tom\` and \`florent\`"
execute "step-13-CONSUME.sh" "Let's consume the message, and confirm \`tom\` and \`florent\` are encrypted"
execute "step-14-ADD_INTERCEPTORS.sh" "Adding interceptor \`crypto-shredding-decrypt\` in \`gateway1\`"
execute "step-15-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-16-CONSUME.sh" "Confirm message from \`tom\` and \`florent\` are encrypted"
execute "step-17-SH.sh" "Listing keys created in Vault"
execute "step-18-SH.sh" "Remove \`florent\` related keys"
execute "step-19-CONSUME.sh" "Let's make sure \`florent\` data are no more readable!"
execute "step-20-DOCKER.sh" "Cleanup the docker environment"
