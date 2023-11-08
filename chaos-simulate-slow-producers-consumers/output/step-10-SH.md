
<details>
<summary>Command output</summary>

```sh

kafka-producer-perf-test \
  --producer.config teamA-sa.properties \
  --record-size 10 \
  --throughput 1 \
  --num-records 10 \
  --topic slow-topic
4 records sent, 0,8 records/sec (0,00 MB/sec), 3089,8 ms avg latency, 3244,0 ms max latency.
5 records sent, 1,0 records/sec (0,00 MB/sec), 3018,2 ms avg latency, 3033,0 ms max latency.
10 records sent, 0,888652 records/sec (0,00 MB/sec), 3047,70 ms avg latency, 3244,00 ms max latency, 3022 ms 50th, 3244 ms 95th, 3244 ms 99th, 3244 ms 99.9th.

```

</details>
      
