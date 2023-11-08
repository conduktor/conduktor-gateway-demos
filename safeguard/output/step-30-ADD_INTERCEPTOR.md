
<details>
<summary>Command output</summary>

```sh

cat step-30-guard-limit-connection.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.safeguard.LimitConnectionPolicyPlugin",
  "priority": 100,
  "config": {
    "maximumConnectionsPerSecond": 1,
    "action": "BLOCK"
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/guard-limit-connection" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-30-guard-limit-connection.json | jq
{
  "message": "guard-limit-connection is created"
}

```

</details>
      
