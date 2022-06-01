#!/bin/bash
#apt-get update \
#    && apt-get install -y \
#       containerd

# get the containerd tarball
cd /tmp
VER_URL="https://github.com/containerd/containerd/releases/latest"

CONTD_VER=`wget ${VER_URL} 2>&1 | grep "Location.*releases/tag/" | cut -d " " -f2 | sed 's/^.*\///'`
echo $CONTD_VER
rm latest
DOWNLOAD_URL="https://github.com/containerd/containerd/releases/download"
CONTD_VER_FILE=`echo ${CONTD_VER} | sed s/^v//`
echo $CONTD_VER_FILE

echo "Downloading containerd ${CONTD_VER} ..."
echo URL: ${DOWNLOAD_URL}/${CONTD_VER}/containerd-${CONTD_VER_FILE}-linux-amd64.tar.gz
curl -L ${DOWNLOAD_URL}/${CONTD_VER}/containerd-${CONTD_VER_FILE}-linux-amd64.tar.gz -o /tmp/containerd-${CONTD_VER}-linux-amd64.tar.gz

# install/extract containerd package
tar -xzf containerd-${CONTD_VER}-linux-amd64.tar.gz -C /usr

# download systemd service file
CONTD_SVC_URL="https://raw.githubusercontent.com/containerd/containerd/main/containerd.service"
curl -L ${CONTD_SVC_URL} -o /tmp/containerd.service

# create containerd systemd service file
cat /tmp/containerd.service | sed 's/\/usr\/local\/bin/\/usr\/bin/g' > /lib/systemd/system/containerd.service

# download runc
RUNC_VER_URL="https://github.com/opencontainers/runc/releases/latest"
RUNC_VER=`wget ${RUNC_VER_URL} 2>&1 | grep "Location.*releases/tag/" | cut -d " " -f2 | sed 's/^.*\///'`
echo $RUNC_VER
RUNC_URL="https://github.com/opencontainers/runc/releases/download/${RUNC_VER}/runc.amd64"

curl -L ${RUNC_URL} -o /tmp/runc.amd64

#install runc
install -m 755 runc.amd64 /usr/bin/runc

# generate default config
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml.default
# make backup copies
#cp /etc/containerd/config.toml /etc/containerd/config.toml.orig
cp /etc/containerd/config.toml.default /etc/containerd/config.toml

# set SystemCgroup to "true"
cat /etc/containerd/config.toml | sed "s/SystemdCgroup \= false/SystemdCgroup \= true/" > /etc/containerd/config.toml.new
cp /etc/containerd/config.toml.new /etc/containerd/config.toml

# restart containerd
systemctl daemon-reload
systemctl enable --now containerd