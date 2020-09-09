output "public_ip" {
  description = "Public IP of instance (or EIP)"
  value       = aws_instance.foundation-node.*.public_ip
}

output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.foundation-node.*.id
}
