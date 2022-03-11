systemctl disable lxd
systemctl stop lxd
systemctl disable kube-apiserver kube-controller-manager kube-scheduler
systemctl stop kube-apiserver kube-controller-manager kube-scheduler