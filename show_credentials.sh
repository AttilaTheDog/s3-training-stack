#!/bin/bash
for i in $(seq -w 1 15); do
  source /opt/s3-training-stack/secrets/minio${i}.env
  echo "training${i}: $MINIO_ROOT_USER / $MINIO_ROOT_PASSWORD"
done
