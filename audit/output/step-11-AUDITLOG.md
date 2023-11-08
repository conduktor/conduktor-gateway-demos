
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin")'
[2024-01-22 17:31:50,179] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 8 messages
{
  "id": "216b743a-379d-489d-b2ae-8dac2b2d27b9",
  "source": "krn://cluster=zRvhZfWOT3qVJ0X3WpaE1A",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:57067"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T16:31:45.555120841Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin",
    "message": "Request parameters do not satisfy the configured policy. Topic 'cars' with invalid value for 'acks': 1. Valid value is one of the values: -1. Topic 'cars' with invalid value for 'compressions': SNAPPY. Valid value is one of the values: [GZIP, NONE]"
  }
}

```

</details>
      
