provider "tencentcloud" {
  region  = var.region
  version = "~> 1.38"
}

resource "random_id" "cvm_id" {
  byte_length = 8
}

data "tencentcloud_availability_zones" "available_zones" {
}

data "tencentcloud_instance_types" "available_instance_types" {
  filter {
    name   = "instance-family"
    values = ["S3"]
  }

  cpu_core_count = 2
  memory_size    = 4
}

data "tencentcloud_vpc_instances" "available_vpc" {
  name = "harmony"
}

data "tencentcloud_vpc_subnets" "available_subnet" {
  availability_zone = data.tencentcloud_availability_zones.available_zones.zones.0.name
  vpc_id = data.tencentcloud_vpc_instances.available_vpc.instance_list.0.vpc_id
}

data "tencentcloud_key_pairs" "key_pair" {
  key_name = var.ssh_key_name
}

data "tencentcloud_security_groups" "available_security_groups" {
  name = "harmony"
}

resource "tencentcloud_instance" "main" {
  instance_name              = "node-${random_id.cvm_id.hex}"
  availability_zone          = data.tencentcloud_availability_zones.available_zones.zones.0.name
  image_id                   = "img-1u6l2i9l"
  instance_type              = "S3.MEDIUM4"
  system_disk_type           = "CLOUD_PREMIUM"
  system_disk_size           = 80
  hostname                   = "node-${random_id.cvm_id.hex}"
  key_name                   = data.tencentcloud_key_pairs.key_pair.key_pair_list.0.key_id
  vpc_id                     = data.tencentcloud_vpc_instances.available_vpc.instance_list.0.vpc_id
  subnet_id                  = data.tencentcloud_vpc_subnets.available_subnet.instance_list.0.subnet_id
  security_groups            = [data.tencentcloud_security_groups.available_security_groups.security_groups.0.security_group_id]
  allocate_public_ip         = true
  internet_max_bandwidth_out = 20
  count                      = var.cvm_count

  provisioner "remote-exec" {
    inline = [
      "setenforce 0",
      "sed -i /etc/selinux/config -r -e 's/^SELINUX=.*/SELINUX=disabled/g'",
    ]
    connection {
      host        = tencentcloud_instance.main.0.public_ip
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_private_key_path)
      timeout     = "1m"
    }
  }
}

output "public_ip" {
  value = tencentcloud_instance.main.0.public_ip
}
