
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin")'
[2024-01-23 01:15:33,367] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 14 messages
{
  "id": "d1e471db-5b31-47ef-a2b1-9305d4c496d9",
  "source": "krn://cluster=lDdK_Y4rQRqw-gRUoD-XXA",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:28677"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-23T00:15:29.448555130Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.SchemaPayloadValidationPolicyPlugin",
    "message": "Request parameters do not satisfy the configured policy. Topic 'topic-json-schema' has invalid json schema payload: [#/hobbies: expected minimum item count: 2, found: 1, #/name: expected minLength: 3, actual: 1, #/email: [bad email] is not a valid email address, #/address/city: expected minLength: 2, actual: 0, #/address/street: expected maxLength: 15, actual: 56]"
  }
}

```

</details>
      
