#!/bin/sh

. utils.sh

header 'SQL Based Data Quality Producer'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`cars\` on \`teamA\`"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor \`myDataQualityProducer\`"
execute "step-09-PRODUCE.sh" "Producing 1 message in \`cars\`"
execute "step-10-PRODUCE.sh" "Producing 1 message in \`cars\`"
execute "step-11-AUDITLOG.sh" "Check in the audit log that message was denied"
execute "step-12-PRODUCE.sh" "Producing 1 message in \`cars\`"
execute "step-13-CONSUME.sh" "Consuming from \`cars\`"
execute "step-14-CONSUME.sh" "Consuming from \`dead-letter-topic\`"
