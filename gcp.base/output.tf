output "ip" {
  value = "${google_compute_instance.node.network_interface.0.access_config.0.nat_ip}"
}

output "name" {
  value = "${google_compute_instance.node.name}"
}

output "instance_id" {
  value = "${google_compute_instance.node.instance_id}"
}

output "instance_boot_disk_source" {
  value = "${google_compute_instance.node.boot_disk.0.source}"
}

output "instance_image_id" {
  value = "${google_compute_image.node_image.id}"
}

output "instance_image_link" {
  value = "${google_compute_image.node_image.self_link}"
}