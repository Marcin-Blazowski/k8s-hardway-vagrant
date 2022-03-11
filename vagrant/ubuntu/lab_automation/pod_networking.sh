#!/bin/bash
HOSTNAME=$(hostname -s)

cd $HOME

# Install CNI plugins
CNI_VER=$(wget https://github.com/containernetworking/plugins/releases/latest 2>&1 | grep "Location.*releases/tag/" | cut -d " " -f2 | sed 's/^.*\///')

echo $CNI_VER

cd /tmp
#wget -q --show-progress --https-only --timestamping https://github.com/containernetworking/plugins/releases/download/${CNI_VER}/cni-plugins-linux-amd64-${CNI_VER}.tgz
echo "Downloading CNI ${CNI_VER} plugins..."
curl -L https://github.com/containernetworking/plugins/releases/download/${CNI_VER}/cni-plugins-linux-amd64-${CNI_VER}.tgz -o /tmp/cni-plugins-linux-amd64-${CNI_VER}.tgz

tar -xzvf cni-plugins-linux-amd64-${CNI_VER}.tgz --directory /opt/cni/bin/


# deploy weave network as pod in the cluster
cd
wget https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr  -d '\n') -O weave-on-pods.yaml

kubectl apply -f weave-on-pods.yaml
