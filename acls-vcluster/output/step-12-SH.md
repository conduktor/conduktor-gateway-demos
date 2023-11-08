
<details>
<summary>Command output</summary>

```sh

kafka-acls \
  --bootstrap-server localhost:6969 \
  --command-config aclCluster-admin.properties \
  --add \
  --allow-principal User:consumer \
  --operation read \
  --topic restricted-topic
Adding ACLs for resource `ResourcePattern(resourceType=TOPIC, name=restricted-topic, patternType=LITERAL)`: 
 	(principal=User:consumer, host=*, operation=READ, permissionType=ALLOW) 

Current ACLs for resource `ResourcePattern(resourceType=TOPIC, name=restricted-topic, patternType=LITERAL)`: 
 	(principal=User:consumer, host=*, operation=READ, permissionType=ALLOW) 


```

</details>
      
