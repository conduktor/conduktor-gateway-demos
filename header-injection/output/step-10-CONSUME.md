
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic users \
    --from-beginning \
    --max-messages 2 \
    --timeout-ms 10000 \
    --property print.headers=true 
X-INTERPOLATED:User sa via ip 192.168.65.1,X-MY-KEY:my own value,X-USER:sa	{"name":"tom","username":"tom@conduktor.io","password":"motorhead","visa":"#abc123","address":"Chancery lane, London"}
X-INTERPOLATED:User sa via ip 192.168.65.1,X-MY-KEY:my own value,X-USER:sa	{"name":"florent","username":"florent@conduktor.io","password":"kitesurf","visa":"#888999XZ","address":"Dubai, UAE"}
Processed a total of 2 messages

```

</details>
      
