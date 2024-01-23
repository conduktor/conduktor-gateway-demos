
<details>
<summary>Command output</summary>

```sh

kafka-producer-perf-test \
    --topic physical-kafka \
    --throughput -1 \
    --num-records 2500000 \
    --record-size 255 \
    --producer-props bootstrap.servers=localhost:19092,localhost:19093,localhost:19094
1520125 records sent, 304025,0 records/sec (73,93 MB/sec), 90,6 ms avg latency, 672,0 ms max latency.
801114 records sent, 160222,8 records/sec (38,96 MB/sec), 46,5 ms avg latency, 569,0 ms max latency.
2500000 records sent, 222955,498083 records/sec (54,22 MB/sec), 73,80 ms avg latency, 672,00 ms max latency, 10 ms 50th, 424 ms 95th, 600 ms 99th, 664 ms 99.9th.

```

</details>
      
