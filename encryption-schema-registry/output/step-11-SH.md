
<details>
<summary>Command output</summary>

```sh

kafka-json-schema-console-consumer \
  --bootstrap-server localhost:6969 \
  --consumer.config teamA-sa.properties \
  --property schema.registry.url=http://localhost:8081 \
  --topic customers \
  --from-beginning \
  --max-messages 2 2>&1  /dev/null | grep '{' | jq
{
  "name": "tom",
  "username": "tom@conduktor.io",
  "password": "AAAABQHqEQju0ny6l8L6Zx/T3+4hMLrZJjmC69oIK1xxNhTv9KGw5tt2h2fxgNibN7Mba0k=",
  "visa": "AAAABQF7MrmdzcERWo44vo8jgLtCaeJxXASuqwBz1MPDHHNH8IJW3bJXrKF2HSA5i/gs",
  "address": {
    "location": "AAAABQFeyt+hXx06obdWrIDT3r9T92LfjziK4OMEp9Y5dCxkTxXfH/Gv1XKvUPkOLUD6/D+xthylDwCo",
    "town": "London",
    "country": "UK"
  }
}
{
  "name": "florent",
  "username": "florent@conduktor.io",
  "password": "AAAABQHqEQjuuiJ3wUgH4zkDSmrQR0vPSAL/NGSOe26wZYirsHR6NIo9odeAHR4Sqi3hww==",
  "visa": "AAAABQF7MrmdUPHJlHmpLrlqjYZjBCNrWdyvoZv9u3mNAvfrAIA6qM7GHaMIfsQQXX0Kvb94",
  "address": {
    "location": "AAAABQFeyt+hjdvqVzm+uFO8VLygs0U2UOhuHWB3dyg2VP1KYGVMDg0GS/7V6i4S7oy0KXNvdFYVzGcPRo1REQ==",
    "town": "Dubai",
    "country": "UAE"
  }
}

```

</details>
      
