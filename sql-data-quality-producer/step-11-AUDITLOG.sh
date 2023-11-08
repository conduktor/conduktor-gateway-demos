kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:29093,localhost:29094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.DataQualityProducerInterceptor")'
