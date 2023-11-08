
<details>
<summary>Command output</summary>

```sh

kafka-producer-perf-test \
  --producer-props bootstrap.servers=localhost:6969 \
  --producer.config teamA-sa.properties \
  --record-size 10 \
  --throughput 1 \
  --num-records 10 \
  --topic my-topic
7 records sent, 1,3 records/sec (0,00 MB/sec), 69,4 ms avg latency, 281,0 ms max latency.
[2024-01-22 18:05:24,117] WARN [Producer clientId=perf-producer-client] Got error produce response with correlation id 11 on topic-partition my-topic-0, retrying (2147483646 attempts left). Error: NOT_LEADER_OR_FOLLOWER (org.apache.kafka.clients.producer.internals.Sender)
[2024-01-22 18:05:24,118] WARN [Producer clientId=perf-producer-client] Received invalid metadata error in produce request on partition my-topic-0 due to org.apache.kafka.common.errors.NotLeaderOrFollowerException: For requests intended only for the leader, this error indicates that the broker is not the current leader. For requests intended for any replica, this error indicates that the broker is not a replica of the topic partition.. Going to request metadata update now (org.apache.kafka.clients.producer.internals.Sender)
10 records sent, 1,081198 records/sec (0,00 MB/sec), 70,10 ms avg latency, 281,00 ms max latency, 33 ms 50th, 281 ms 95th, 281 ms 99th, 281 ms 99.9th.

```

</details>
      
