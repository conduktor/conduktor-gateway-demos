
<details>
<summary>Command output</summary>

```sh

curl \
    --request GET 'http://localhost:8888/admin/interceptors/v1/vcluster/teamA' \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent | jq
{
  "interceptors": [
    {
      "name": "guard-on-produce",
      "pluginClass": "io.conduktor.gateway.interceptor.safeguard.ProducePolicyPlugin",
      "apiKey": null,
      "priority": 100,
      "timeoutMs": 9223372036854775807,
      "config": {
        "acks": {
          "value": [
            -1
          ],
          "action": "BLOCK"
        },
        "compressions": {
          "value": [
            "NONE",
            "GZIP"
          ],
          "action": "BLOCK"
        }
      }
    }
  ]
}

```

</details>
      