cat step-08-simulate-leader-elections-errors.json | jq

curl \
    --request POST "http://localhost:8888/admin/interceptors/v1/vcluster/teamA/interceptor/simulate-leader-elections-errors" \
    --header 'Content-Type: application/json' \
    --user 'admin:conduktor' \
    --silent \
    --data @step-08-simulate-leader-elections-errors.json | jq
