
<details>
<summary>Command output</summary>

```sh

docker compose up --detach --wait
 Network cluster-switching_default  Creating
 Network cluster-switching_default  Created
 Container zookeeper  Creating
 Container zookeeper  Created
 Container kafka3  Creating
 Container kafka1  Creating
 Container failover-kafka3  Creating
 Container failover-kafka2  Creating
 Container failover-kafka1  Creating
 Container kafka2  Creating
 Container kafka1  Created
 Container kafka3  Created
 Container failover-kafka1  Created
 Container failover-kafka3  Created
 Container failover-kafka2  Created
 Container kafka2  Created
 Container mirror-maker  Creating
 Container gateway2  Creating
 Container schema-registry  Creating
 Container gateway1  Creating
 gateway1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 gateway2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested 
 Container gateway1  Created
 Container gateway2  Created
 Container schema-registry  Created
 Container mirror-maker  Created
 Container zookeeper  Starting
 Container zookeeper  Started
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Waiting
 Container zookeeper  Healthy
 Container kafka2  Starting
 Container zookeeper  Healthy
 Container zookeeper  Healthy
 Container kafka1  Starting
 Container failover-kafka2  Starting
 Container zookeeper  Healthy
 Container failover-kafka1  Starting
 Container zookeeper  Healthy
 Container kafka3  Starting
 Container zookeeper  Healthy
 Container failover-kafka3  Starting
 Container failover-kafka1  Started
 Container failover-kafka3  Started
 Container kafka2  Started
 Container kafka1  Started
 Container failover-kafka2  Started
 Container kafka3  Started
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container failover-kafka1  Waiting
 Container failover-kafka2  Waiting
 Container failover-kafka3  Waiting
 Container kafka1  Waiting
 Container kafka1  Waiting
 Container kafka2  Waiting
 Container kafka3  Waiting
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container kafka1  Healthy
 Container gateway1  Starting
 Container kafka2  Healthy
 Container failover-kafka1  Healthy
 Container kafka3  Healthy
 Container kafka1  Healthy
 Container failover-kafka2  Healthy
 Container kafka2  Healthy
 Container kafka1  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container schema-registry  Starting
 Container gateway2  Starting
 Container failover-kafka3  Healthy
 Container mirror-maker  Starting
 Container schema-registry  Started
 Container mirror-maker  Started
 Container gateway2  Started
 Container gateway1  Started
 Container failover-kafka3  Waiting
 Container failover-kafka2  Waiting
 Container kafka1  Waiting
 Container schema-registry  Waiting
 Container kafka3  Waiting
 Container mirror-maker  Waiting
 Container kafka2  Waiting
 Container zookeeper  Waiting
 Container gateway1  Waiting
 Container gateway2  Waiting
 Container failover-kafka1  Waiting
 Container zookeeper  Healthy
 Container kafka3  Healthy
 Container kafka2  Healthy
 Container failover-kafka3  Healthy
 Container failover-kafka2  Healthy
 Container failover-kafka1  Healthy
 Container kafka1  Healthy
 Container mirror-maker  Healthy
 Container schema-registry  Healthy
 Container gateway1  Healthy
 Container gateway2  Healthy

```

</details>
      
