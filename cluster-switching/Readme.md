# Cluster Switching

## What is cluster switching?

Conduktor Gateway's cluster switching allows to hot-switch the backend Kafka cluster
without having to change your client configuration or restart Gateway.

This features enables to build a seamless disaster recovery strategy for your Kafka cluster 
when Gateway is deployed in combination with a replication solution (like MirrorMaker, Confluent replicator, ...).

### Architecture diagram

![architecture diagram](images/cluster-switching.png "cluster switching")

## Limitations to consider when designing a disaster recovery strategy

- Cluster switching does not replicate data between clusters. 
  You need to use a replication solution like MirrorMaker to replicate data between clusters.
- Because of their asynchronous nature, replication solutions may lead to data loss in case of a disaster.
- Cluster switching is manual process - automatic failover is not supported yet.
- Concentrated topics offsets: Gateway stores client offsets of concentrated topics in a regular kafka topic. 
  When replicating this topic, there will be no adjustments of potential offsets shifts between the source and failover cluster.
- When switching, Kafka consumers will perform a group rebalance. They will not be able to commit their offset before the rebalance.
  This may lead to a some messages being consumed twice.
  
## Running the demo

### Step 1: Review the environment

As can be seen from `docker-compose.yaml` the demo environment consists of the following:

* A single Zookeeper Server
* A main 3 nodes Kafka cluster
* A failover 3 nodes Kafka cluster
* A 2 nodes Conduktor Gateway server
* A MirrorMaker container

### Step 2: Review the Gateway configuration

The Kafka brokers used by Gateway are stored in `cluster-switching-clusters.yaml` and is mounted into the Gateway container.
The failover cluster is configured with the `gateway.role` property set to `failover`. This cluster is not used by Gateway in nominal mode.

### Step 3: Review the MirrorMaker configuration

MirrorMaker is configured to replicate all topics and groups from the main cluster to the failover cluster (see `mm2.properties`).
One important bit is the `replication.policy.class=org.apache.kafka.connect.mirror.IdentityReplicationPolicy` configuration.
Gateway expects the topics to have the same names on both clusters.


### Step 4: Start the environment
Start the environment with

```bash
docker compose up --wait --detach
```

...

### Step X: Switch to the failover cluster

Use the admin API to switch to the failover cluster:

```bash
      curl \
        --silent \
        --user "admin:conduktor" \
        --request POST 'http://localhost:8888/admin/pclusters/v1/pcluster/main/switch?to=failover'
```

From now on, the cluster with id `main` is actually pointing to the failover cluster.