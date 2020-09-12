output "public_ip" {
   value = aws_lightsail_static_ip.node.*.ip_address
}
