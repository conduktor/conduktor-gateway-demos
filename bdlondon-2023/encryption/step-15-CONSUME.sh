kafka-console-consumer \
    --bootstrap-server localhost:29092,localhost:29093,localhost:29094 \
    --topic teamAcustomers \
    --from-beginning \
    --timeout-ms 5000 \
    --property print.headers=true
