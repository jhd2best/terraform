# init terraform, do it once
* terraform init

# plan terraform for 20 nodes
* terraform plan -var 'vm_count=20'

# deploy 20 nodes
* terraform apply -var 'vm_count=20' -auto-approve

# terminate all nodes
* terraform destroy

# You may also use lightsail.sh to manage lightsail instance for mainnet
$ ./lightsail.sh -h
lightsail.sh [options] action

Options:
   -h                print this help
   -s shard          specify shard id (default: s0)
   -i first_index    specify the first index of the blskey in this instance, delimited by ,
   -r region         specify the region (default: us-west-2)

Actions:
   create            create lightsail instances
   port              manage public ports
   ip                list all ip addresses of lightsail instances

Examples:
   lightsail.sh -s s0 -i 12,16 create
   lightsail.sh -s s0 -i 12,16 port
   lightsail.sh -s s0 -i 12,16 ip

