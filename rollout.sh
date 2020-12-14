#!/bin/bash
# run Packer and pipe and transport output to readable file for Terraform
# source: https://discuss.devopscube.com/t/how-to-get-the-ami-id-after-a-packer-build/36
packer build -machine-readable ami.json > amiresult.txt 
cat amiresult.txt | grep 'artifact,0,id' | cut -d, -f6 | cut -d: -f2 |  tr -d "\n" > ami.txt

# run Terraform to provision the resources
terraform apply