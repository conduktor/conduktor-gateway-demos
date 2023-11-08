
<details>
<summary>Command output</summary>

```sh

curl \
  --request GET 'http://localhost:8200/v1/transit/keys/?list=true' \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token" | jq -r ".data.keys"
[
  "secret-for-florent",
  "secret-for-tom"
]

```

</details>
      
