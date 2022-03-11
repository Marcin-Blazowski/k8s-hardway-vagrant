#!/bin/bash

# Download binaries
cd /tmp
ETCD_VER=`wget https://github.com/etcd-io/etcd/releases/latest 2>&1 | grep "Location.*releases/tag/" | cut -d " " -f2 | sed 's/^.*\///'`
echo $ETCD_VER
rm latest
DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download

echo "Downloading ETCD ${ETCD_VER} ..."
curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
cp /tmp/etcd-${ETCD_VER}-linux-amd64/etcd* /usr/local/bin/

# configure ETCD
{
  mkdir -p /etc/etcd /var/lib/etcd
  cd ~
  cp ca.crt etcd-server.key etcd-server.crt /etc/etcd/
}

# get local IP address (assigned to enp0s8 interface, this is Virtualbox in id provided to Ubuntu)
INTERNAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
ETCD_NAME=$(hostname -s)

# create etcd.service systemd unit file
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster master-1=https://192.168.5.11:2380,master-2=https://192.168.5.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start ETCD server
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}
