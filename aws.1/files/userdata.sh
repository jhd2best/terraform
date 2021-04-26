#!/bin/bash

# setup harmomy user environment
mkdir -p /home/ec2-user/data /home/ec2-user/.hmy /home/ec2-user/.config/rclone

chown -R ec2-user:ec2-user /home/ec2-user/data /home/ec2-user/.hmy /home/ec2-user/.config

# install base environment
yum update -y
yum install -y bind-utils jq

# install rclone
curl https://rclone.org/install.sh | bash

# install node_exporter
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
tar xfz node_exporter-1.0.1.linux-amd64.tar.gz
mv -f node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin
rm -rf node_exporter-1.0.1.linux-amd64.tar.gz node_exporter-1.0.1.linux-amd64
useradd -rs /bin/false node_exporter
chown node_exporter.node_exporter /usr/local/bin/node_exporter
