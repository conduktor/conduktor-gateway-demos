
<details>
<summary>Command output</summary>

```sh

echo nb schemas = $(curl --silent http://localhost:8081/subjects/ | jq 'length')
curl --silent http://localhost:8081/subjects/ | jq 'length'
nb schemas = 3

```

</details>
      
