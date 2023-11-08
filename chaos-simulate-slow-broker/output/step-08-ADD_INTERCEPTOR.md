
<details>
<summary>Command output</summary>

```sh

cat step-08-simulate-slow-broker.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateSlowBrokerPlugin",
  "priority": 100,
  "config": {
    "rateInPercent": 100,
    "minLatencyMs": 2000,
    "maxLatencyMs": 2001
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/simulate-slow-broker" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-simulate-slow-broker.json | jq
{
  "message": "simulate-slow-broker is created"
}

```

</details>
      
