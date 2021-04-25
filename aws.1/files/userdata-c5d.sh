#!/bin/bash

# create data disk
fdisk /dev/nvme1n1 <<EOF
n
p
1


w
EOF

mkfs.ext4 /dev/nvme1n1p1
sleep 10

# mount data disk
mkdir /data && \
mount /dev/nvme1n1p1 /data && \
mkdir /data/harmony

cp /etc/fstab /etc/fstab.bak
echo `blkid /dev/nvme1n1p1 | awk '{print $2}' | sed 's/\"//g'` /data ext4 defaults 0 0 | tee -a /etc/fstab

# install base environment
yum update -y
yum install -y bind-utils jq

# install rclone
curl https://rclone.org/install.sh | bash

# setup harmomy user environment
mkdir -p /home/ec2-user/.hmy /home/ec2-user/.config/rclone
ln -s /data/harmony /home/ec2-user/data

chown -R ec2-user:ec2-user /home/ec2-user/.hmy /home/ec2-user/.config /data/harmony /home/ec2-user/data

# install node_exporter
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
tar xfz node_exporter-1.0.1.linux-amd64.tar.gz
mv -f node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin
rm -rf node_exporter-1.0.1.linux-amd64.tar.gz node_exporter-1.0.1.linux-amd64
useradd -rs /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter
