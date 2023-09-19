echo 'Step 06 SH Verify the disabled algorithms'
docker logs  gateway1 2>&1  | grep "disabledAlgorithms"