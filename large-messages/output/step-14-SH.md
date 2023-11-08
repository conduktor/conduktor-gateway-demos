
<details>
<summary>Command output</summary>

```sh

docker compose exec cli-aws \
    aws \
        --profile minio \
        --endpoint-url=http://minio:9000 \
        --region eu-south-1 \
        s3 \
        ls s3://bucket --recursive --human-readable
2024-01-22 22:43:33   40.0 MiB large-messages/eaf8c224-6a8b-4432-b388-bee3b11585e4

```

</details>
      
