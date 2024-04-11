#!/bin/bash
docker compose exec cli-aws \
  aws \
    --profile minio \
    --endpoint-url=http://minio:9000 \
    --region eu-south-1 \
    s3api create-bucket \
      --bucket bucket