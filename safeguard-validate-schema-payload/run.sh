#!/bin/bash

. utils.sh

header 'Schema Producer Interceptor'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topics topic-json,topic-avro,topic-protobuf on teamA"
execute "step-07-ADD_INTERCEPTOR.sh" "Adding interceptor guard-schema-payload-validate"
execute "step-08-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-12-SH.sh" "Let's register these schemas to the Schema Registry"
execute "step-13-SH.sh" "Let's asserts number of registered schemas"
execute "step-14-SH.sh" "Let's produce invalid payload to the json schema"
execute "step-15-SH.sh" "Let's produce invalid payload to the avro schema"
execute "step-16-AUDITLOG.sh" "Check in the audit log that message was denied"
execute "step-17-SH.sh" "Let's produce invalid payload to the protobuf schema"
execute "step-18-AUDITLOG.sh" "Check in the audit log that message was denied"
execute "step-19-DOCKER.sh" "Tearing down the docker environment"
