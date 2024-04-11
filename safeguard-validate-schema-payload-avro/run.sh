#!/bin/bash

. utils.sh

header 'Schema Payload Validation for Avro'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic topic-avro on teamA"
execute "step-08-SH.sh" "Let's register it to the Schema Registry"
execute "step-10-SH.sh" "Let's send invalid data"
execute "step-11-SH.sh" "Let's consume it back"
execute "step-12-ADD_INTERCEPTOR.sh" "Adding interceptor guard-schema-payload-validate"
execute "step-13-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-15-SH.sh" "Let's update the schema with our validation rules"
execute "step-16-SH.sh" "Let's asserts number of registered schemas"
execute "step-17-SH.sh" "Let's produce the same invalid payload again"
execute "step-18-AUDITLOG.sh" "Check in the audit log that message was denied"
execute "step-19-SH.sh" "Let's now produce a valid payload"
execute "step-20-SH.sh" "And consume it back"
execute "step-21-DOCKER.sh" "Tearing down the docker environment"
