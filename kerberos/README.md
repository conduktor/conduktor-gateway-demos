# Conduktor Platform with Kafka Cluster(Kerberos)

This will start :
* Conduktor platform with external postgres database
* Local Kafka Cluster (Kerberos)
* Local Schema Registry Cluster (Basic Auth)
* Local Kafka Connect (Basic Auth)

## Known caveats
This is a woarkaroud that can be applied via yaml configuration to provision the cluster. 
Same workaround (by providing kafka properties) will work via API (private ones).
Keytab must be mounted into the container.

At this stage you cannot update the cluster from the UI since Kerberos is not officially supported.


## How to start ?

Execute the following command: 
```sh
$ ./start.sh
```

Wait a bit and you should get your platform up and running on [http://localhost:8080].

RBAC is enabled.

## Possible logins
| Login          | Password | Role   |
|----------------|----------|--------|
| admin@demo.dev | adminpwd | Admin  |
| alice@demo.dev | alicepwd | Member |
| bob@demo.dev   | bobpwd   | Member |

## How to stop the platform ?

Execute the following command: 
```sh
$ ./stop.sh
```
