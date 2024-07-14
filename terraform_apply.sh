#!/bin/bash

cd lambdas
./prepare_lambdas.sh

cd ..

cd terraform

terraform init

# Lambdas are created in parallel due to their long creation time
terraform apply -auto-approve -target=module.lambdas

sleep 10

# Serial processing needed to prevent concurrency errors in gateway integration creation
terraform apply -auto-approve -parallelism=1

sleep 10

# The newly built frontend is uploaded to the S3 bucket in a separate step, to workaround the fileset function only scanning during plan, not on execution
terraform apply -auto-approve -target=aws_s3_object.object