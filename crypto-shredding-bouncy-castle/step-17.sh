echo 'Step 17 SH Listing keys created in Vault'
curl \
  --request GET 'http://localhost:8200/v1/transit/keys/?list=true' \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token" | jq -r ".data.keys"
