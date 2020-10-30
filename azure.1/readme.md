# login to azure accont
az login

# init
terraform init

# plan
terraform plan

# deploy 5 nodes
terraform apply -var 'vm_count=5' -var 'shard=s1' -auto-approve
terraform apply -var 'vm_count=5' -var 'shard=s2' -auto-approve

# terminate
terraform destroy
