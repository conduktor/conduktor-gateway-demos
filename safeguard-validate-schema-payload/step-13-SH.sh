#!/bin/bash
echo nb schemas = $(curl --silent http://localhost:8081/subjects/ | jq 'length')