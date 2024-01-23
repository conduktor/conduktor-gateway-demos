
<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config user-1.properties \
    --list
[2024-01-23 00:17:32,589] WARN [Principal=:f3e0ecec-42d0-455e-88aa-5db45560c160]: Expiring credential expires at Tue Jan 23 00:18:32 CET 2024, so buffer times of 60 and 300 seconds at the front and back, respectively, cannot be accommodated.  We will refresh at Tue Jan 23 00:18:21 CET 2024. (org.apache.kafka.common.security.oauthbearer.internals.expiring.ExpiringCredentialRefreshingLogin)
__consumer_offsets
_acls
_auditLogs
_consumerGroupSubscriptionBackingTopic
_encryptionConfig
_interceptorConfigs
_license
_offsetStore
_schemas
_topicMappings
_topicRegistry
_userMapping
cars

```

</details>
      