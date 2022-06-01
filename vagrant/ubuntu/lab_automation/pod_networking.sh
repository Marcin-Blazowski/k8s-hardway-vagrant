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


# weave network plugin does not work with latest version of containerd
# switching to flannel
# deploy weave network as pod in the cluster
cd
#wget https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr  -d '\n') -O weave-on-pods.yaml
#kubectl apply -f weave-on-pods.yaml


# patch the info about the node in the control plane
# this is somehow needed by the flannel
# kubectl patch node $(hostname) -p '{"spec":{"podCIDR":"10.33.0.0/16"}}'

curl -L https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml -o kube-flannel.yml.orig

# specify the network interface to enp0s8 which is Vagrant host-only network
sed '/\-\-ip\-masq$/a \ \ \ \ \ \ \ \ - --iface=enp0s8' kube-flannel.yml.orig > kube-flannel.yml.new

# change pod CIDR to 10.33.0.0/16
sed 's/10\.244\.0\.0\/16/10.33.0.0\/16/g' kube-flannel.yml.new > kube-flannel.yml

kubectl apply -f kube-flannel.yml
