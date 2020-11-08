variable "public_key_path" {
  description = "The path to the SSH Public Key to add to GCP."
  default     = "~/.ssh/gcp_mp.pub"
}

variable "private_key_path" {
  description = "The path to the SSH Private Key to access GCP instance."
  default     = "~/.ssh/gcp_mp.pem"
}

variable "node_volume_size" {
  description = "Root Volume size of the GCP node instance"
  default     = 50
}

variable "node_instance_type" {
  description = "Instance type of the GCP node instance"
  default     = "e2-medium" // 2C4G enough for mainnet node
}

variable "node_operate_system" {
  description = "Base operate system of the GCP node instance"
  default     = "projects/ubuntu-os-cloud/global/images/ubuntu-1804-bionic-v20201014"
}

variable "zone" {
  default = "us-east1-b"
}

variable "vpc_name" {
  description = "The network name of the GCP nodes"
  default     = "hmy-mainnet-vpc"
}

variable "harmony_version" {
  default = "latest"
}

variable "harmony_disk_source" {
  default = ""
}