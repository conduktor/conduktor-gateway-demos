#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _conduktor_gateway_auditlogs \
    --from-beginning \
    --timeout-ms 3000 \| jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin")'
