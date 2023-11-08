
<details>
<summary>Command output</summary>

```sh

kafka-acls \
  --bootstrap-server localhost:6969 \
  --command-config aclCluster-admin.properties \
  --add \
  --allow-principal User:consumer \
  --operation read \
  --group console-consumer \
  --resource-pattern-type prefixed
Adding ACLs for resource `ResourcePattern(resourceType=GROUP, name=console-consumer, patternType=PREFIXED)`: 
 	(principal=User:consumer, host=*, operation=READ, permissionType=ALLOW) 

Current ACLs for resource `ResourcePattern(resourceType=GROUP, name=console-consumer, patternType=PREFIXED)`: 
 	(principal=User:consumer, host=*, operation=READ, permissionType=ALLOW) 


```

</details>
      
