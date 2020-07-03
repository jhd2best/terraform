# set env for Tencent US accont
export TENCENTCLOUD_SECRET_ID="<your tencentcloud secret id>"
export TENCENTCLOUD_SECRET_KEY="<your tencentcloud secret key>"

# init
terraform init

# plan
terraform plan

# deploy 20 nodes
terraform deploy -var 'cvm_count=20' -var 'region=na-siliconvalley' -var 'ssh_key_name=<your ssh key name>' -auto-prove

# terminate
terraform destroy
