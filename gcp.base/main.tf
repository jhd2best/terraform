// set a different cloud credentials
// export GOOGLE_CLOUD_KEYFILE_JSON=benchmark-209420-a7a77ae89c9c.json

provider "google" {
  project = "benchmark-209420"
  version = "~> 2.20"
}

resource "google_compute_instance" "node" {
  name         = "harmony-gcp-marketplace"
  machine_type = var.node_instance_type
  zone         = var.zone

  metadata = {
    ssh-keys = "gce-user:${file(var.public_key_path)}"
  }

  boot_disk {
    initialize_params {
      image = var.node_operate_system
      size  = var.node_volume_size
    }
  }

  network_interface {
    network = var.vpc_name

    access_config {
      // Include this section to give the VM an external ip address
    }
  }

  provisioner "file" {
    source      = "files/node_exporter.service"
    destination = "/home/gce-user/node_exporter.service"
    connection {
      host  = google_compute_instance.node.network_interface.0.access_config.0.nat_ip
      type  = "ssh"
      user  = "gce-user"
      private_key = file(var.private_key_path)
      agent = true
    }
  }

  provisioner "file" {
    source      = "files/rclone.conf"
    destination = "/home/gce-user/rclone.conf"
    connection {
      host  = google_compute_instance.node.network_interface.0.access_config.0.nat_ip
      type  = "ssh"
      user  = "gce-user"
      private_key = file(var.private_key_path)
      agent = true
    }
  }

  provisioner "file" {
    source      = "files/rclone.sh"
    destination = "/home/gce-user/rclone.sh"
    connection {
      host  = google_compute_instance.node.network_interface.0.access_config.0.nat_ip
      type  = "ssh"
      user  = "gce-user"
      private_key = file(var.private_key_path)
      agent = true
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo setenforce 0",
      "sudo sed -i /etc/selinux/config -r -e 's/^SELINUX=.*/SELINUX=disabled/g'",
      "sudo apt update && sudo apt install -y jq psmisc unzip",
      "chmod +x rclone.sh",
      "mkdir -p /home/gce-user/.config/rclone",
      "mv -f rclone.conf /home/gce-user/.config/rclone",
      "curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz",
      "tar xfz node_exporter-1.0.1.linux-amd64.tar.gz",
      "sudo mv -f node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin",
      "sudo useradd -rs /bin/false node_exporter",
      "rm -rf node_exporter-1.0.1.linux-amd64.tar.gz node_exporter-1.0.1.linux-amd64",
      "sudo cp -f node_exporter.service /etc/systemd/system/node_exporter.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable node_exporter.service",
      "sudo systemctl start node_exporter.service",
      "curl https://rclone.org/install.sh | sudo bash",
    ]
    connection {
      host  = google_compute_instance.node.network_interface.0.access_config.0.nat_ip
      type  = "ssh"
      user  = "gce-user"
      private_key = file(var.private_key_path)
      agent = true
    }
  }
}

resource "google_compute_image" "node_image" {
  name = "harmony-gcp-marketplace-${var.harmony_version}"
  source_disk = var.harmony_disk_source
}