variable "shard" {
  description = "the shard of the Harmony Node"
  default     = "s1"
}

variable "blskey_index" {
  description = "the index of the Harmony Node BlsKey"
  default     = "0"
}

variable "network" {
  description = "the network of Azure vm for node"
  default     = "mainnet"
}

variable "type" {
  description = "the type of the network"
  default     = "mainnet"
}

variable "location" {
  description = "the location of Azure vm for node"
  default     = "westus"
}

variable "vm_size" {
  description = "The size of the Azure vm"
  default     = "Standard_A2_v2"
}

variable "vm_count" {
  description = "The number of Azure vm"
  default     = 2
}

variable "ssh_private_key_path" {
  description = "your SSH private key path"
  default     = "~/.ssh/harmony-node.pem"
}

variable "ssh_public_key_path" {
  description = "your SSH public key path"
  default     = "~/.ssh/harmony-node.pub"
}

variable "default_key" {
  default = ""
}
