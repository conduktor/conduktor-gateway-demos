#!/bin/sh

. utils.sh

header 'Schema Payload Validation for Json Schema'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`topic-json-schema\` on \`teamA\`"
execute "step-09-SH.sh" "Let's register it to the Schema Registry"
execute "step-11-SH.sh" "Let's send invalid data"
execute "step-12-SH.sh" "Let's send invalid data using the protocol"
execute "step-13-SH.sh" "Let's consume it back"
execute "step-14-ADD_INTERCEPTOR.sh" "Adding interceptor \`guard-schema-payload-validate\`"
execute "step-15-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-16-SH.sh" "Let's send invalid data using the protocol again"
execute "step-17-AUDITLOG.sh" "Check in the audit log that message was denied"
execute "step-18-SH.sh" "Let's now produce a valid payload"
execute "step-19-SH.sh" "And consume it back"
execute "step-20-DOCKER.sh" "Tearing down the docker environment"
