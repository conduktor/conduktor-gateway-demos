
<details>
<summary>Command output</summary>

```sh

kafka-run-class kafka.tools.EndToEndLatency \
    localhost:19092,localhost:19093,localhost:19094 \
    physical-kafka 10000 all 255
WARNING: The 'kafka.tools' package is deprecated and will change to 'org.apache.kafka.tools' in the next major release.
0	46.866875
1000	1.941292
2000	1.2305
3000	1.301917
4000	1.11525
5000	1.141208
6000	2.510167
7000	0.9730829999999999
8000	0.916584
9000	1.052875
Avg latency: 1,5754 ms
Percentiles: 50th = 1, 99th = 7, 99.9th = 23

```

</details>
      
