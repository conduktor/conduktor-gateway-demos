echo 'Step 18 SH Remove `florent` related keys'
curl \
  --request POST 'http://localhost:8200/v1/transit/keys/secret-for-florent/config' \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token" \
  --header "content-type: application/json" \
  --data-raw '{"min_decryption_version":"1","min_encryption_version":1,"deletion_allowed":true,"auto_rotate_period":0}' > /dev/null

curl \
  --request DELETE http://localhost:8200/v1/transit/keys/secret-for-florent \
  --silent \
  --header "X-Vault-Token: vault-plaintext-root-token"
