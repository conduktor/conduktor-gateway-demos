
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:29093,localhost:29094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.DataQualityProducerInterceptor")'
[2024-01-23 02:14:19,341] WARN [Consumer clientId=console-consumer, groupId=console-consumer-21214] Connection to node -3 (localhost/127.0.0.1:29094) could not be established. Broker may not be available. (org.apache.kafka.clients.NetworkClient)
[2024-01-23 02:14:19,341] WARN [Consumer clientId=console-consumer, groupId=console-consumer-21214] Bootstrap broker localhost:29094 (id: -3 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)
[2024-01-23 02:14:22,567] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 9 messages
{
  "id": "ac3e42a2-611f-4c0b-bce0-3ba7de61a5df",
  "source": "krn://cluster=kk0VWCjWSCeOmCDgRYmWVw",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:29369"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-23T01:14:18.150366758Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.DataQualityProducerInterceptor",
    "message": "Request parameters do not satisfy the configured policy: Data quality policy is violated."
  }
}

```

</details>
      
