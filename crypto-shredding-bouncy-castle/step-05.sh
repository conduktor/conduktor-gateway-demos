echo 'Step 05 SH Verify the security provider setup'
docker logs  gateway1 2>&1  | grep "Security Provider"