#!/bin/bash

# Apply the entire Terraform configuration to create the build files
terraform apply -auto-approve -parallelism=1

# Apply the Terraform configuration again, but only for the aws_s3_object.object resource
terraform apply -auto-approve -target=aws_s3_object.object