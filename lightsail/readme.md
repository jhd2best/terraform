# init terraform, do it once
* terraform init

# plan terraform for 20 nodes
* terraform plan -var 'vm_count=20'

# deploy 20 nodes
* terraform apply -var 'vm_count=20' -auto-approve

# terminate all nodes
* terraform destroy
