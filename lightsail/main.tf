provider "aws" {
	region = var.aws_region
   shared_credentials_file = "~/.aws/credentials"
   profile = "default"
}

resource "aws_lightsail_static_ip" "node" {
   count             = var.vm_count
   name              = "stn.eip.${count.index}"
}

resource "aws_lightsail_instance" "node" {
	count					= var.vm_count
	name              = "stn.node.${count.index}"
	availability_zone = "us-west-2b"
	blueprint_id      = "ubuntu_20_04"
	bundle_id         = "micro_2_0"
	key_pair_name     = "haochen-harmony"
	tags = {
		Name = "stn.node.${count.index}"
	}
}

resource "aws_lightsail_static_ip_attachment" "node" {
   count             = var.vm_count
   static_ip_name    = aws_lightsail_static_ip.node[count.index].id
   instance_name     = aws_lightsail_instance.node[count.index].id
}
