variable "region" {
  description = "the region of Tencent US cvm for node"
  default     = "na-siliconvalley"
}

variable "cvm_count" {
  description = "The number of Tencent US cvm"
  default     = 1
}

variable "ssh_private_key_path" {
  description = "your SSH private key path"
  default     = "~/.ssh/id_rsa"
}

variable "ssh_public_key_path" {
  description = "your SSH public key path"
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_key_name" {
  description = "your SSH public key name in Tencent US console"
  default     = "harmony_prod"
}