
<details>
<summary>Command output</summary>

```sh

cat step-08-simulate-leader-elections-errors.json | jq
{
  "pluginClass": "io.conduktor.gateway.interceptor.chaos.SimulateLeaderElectionsErrorsPlugin",
  "priority": 100,
  "config": {
    "rateInPercent": 50
  }
}

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/simulate-leader-elections-errors" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-simulate-leader-elections-errors.json | jq
{
  "message": "simulate-leader-elections-errors is created"
}

```

</details>
      
