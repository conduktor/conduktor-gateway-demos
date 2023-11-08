
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:6969 \
    --consumer.config teamA-sa.properties \
    --topic cars \
    --from-beginning \
    --timeout-ms 10000 \
    --group group-with-aggressive-autocommit \
 | jq
[2024-01-23 00:23:30,434] WARN [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] Received error POLICY_VIOLATION from node 2147483646 when making an ApiVersionsRequest with correlation id 4. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-01-23 00:23:31,075] WARN [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] Received error POLICY_VIOLATION from node 2147483646 when making an ApiVersionsRequest with correlation id 10. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-01-23 00:23:32,226] WARN [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] Received error POLICY_VIOLATION from node 2147483646 when making an ApiVersionsRequest with correlation id 15. Disconnecting. (org.apache.kafka.clients.NetworkClient)
[2024-01-23 00:23:32,525] ERROR [Consumer clientId=console-consumer, groupId=group-with-aggressive-autocommit] JoinGroup failed due to unexpected error: Request parameters do not satisfy the configured policy. (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
[2024-01-23 00:23:32,526] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.KafkaException: Unexpected error in join group response: Request parameters do not satisfy the configured policy.
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$JoinGroupResponseHandler.handle(AbstractCoordinator.java:711)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$JoinGroupResponseHandler.handle(AbstractCoordinator.java:603)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$CoordinatorResponseHandler.onSuccess(AbstractCoordinator.java:1270)
	at org.apache.kafka.clients.consumer.internals.AbstractCoordinator$CoordinatorResponseHandler.onSuccess(AbstractCoordinator.java:1245)
	at org.apache.kafka.clients.consumer.internals.RequestFuture$1.onSuccess(RequestFuture.java:206)
	at org.apache.kafka.clients.consumer.internals.RequestFuture.fireSuccess(RequestFuture.java:169)
	at org.apache.kafka.clients.consumer.internals.RequestFuture.complete(RequestFuture.java:129)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient$RequestFutureCompletionHandler.fireCompletion(ConsumerNetworkClient.java:617)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.firePendingCompletedRequests(ConsumerNetworkClient.java:427)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:312)
	at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:251)
	at org.apache.kafka.clients.consumer.KafkaConsumer.pollForFetches(KafkaConsumer.java:1255)
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1186)
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1159)
	at kafka.tools.ConsoleConsumer$ConsumerWrapper.receive(ConsoleConsumer.scala:473)
	at kafka.tools.ConsoleConsumer$.process(ConsoleConsumer.scala:103)
	at kafka.tools.ConsoleConsumer$.run(ConsoleConsumer.scala:77)
	at kafka.tools.ConsoleConsumer$.main(ConsoleConsumer.scala:54)
	at kafka.tools.ConsoleConsumer.main(ConsoleConsumer.scala)
Processed a total of 0 messages

```

</details>
      
