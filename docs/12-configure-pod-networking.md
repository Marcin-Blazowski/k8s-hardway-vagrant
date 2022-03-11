Previous: [Configuring Kubectl](11-configuring-kubectl.md)

# Provisioning Pod Network

We chose to use CNI - [weave](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/) as our networking option.

### Install CNI plugins

Download the CNI Plugins required for weave on each of the worker nodes - `worker-1` and `worker-2` and install (extract to the target directory:)

```
CNI_VER=`wget https://github.com/containernetworking/plugins/releases/latest 2>&1 \
  | grep "Location.*releases/tag/" | cut -d " " -f2 | sed 's/^.*\///'`

echo $CNI_VER

cd /tmp
wget -q --show-progress --https-only --timestamping \ 
  https://github.com/containernetworking/plugins/releases/download/${CNI_VER}/cni-plugins-linux-amd64-${CNI_VER}.tgz

tar -xzvf cni-plugins-linux-amd64-${CNI_VER}.tgz --directory /opt/cni/bin/
```

Reference: https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#cni

### Deploy Weave Network

Deploy weave network. Run only once on the `master` node (or any other node on which you have kubectl with admin priviledges configured.)


```
cd
wget https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr  -d '\n') -O weave-on-pods.yaml

kubectl apply -f weave-on-pods.yaml
```

It will take some time (a few minutes) for the image to be downloaded and deployed as a POD on worker nodes.

Weave uses POD CIDR of `10.32.0.0/12` by default.

## Verification

If networking pods (weave) are deployed with success you should have ready cluster worker nodes. List the registered Kubernetes nodes from the master node:

```
kubectl get nodes
```

> output

```
root@master-1:~# kubectl get nodes
NAME       STATUS   ROLES    AGE    VERSION
worker-1   Ready    <none>   7d7h   v1.23.4
worker-2   Ready    <none>   6d9h   v1.23.4
```

```
kubectl get pods -n kube-system
```

> output

```
NAME              READY   STATUS    RESTARTS   AGE
weave-net-58j2j   2/2     Running   0          89s
weave-net-rr5dk   2/2     Running   0          89s
```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/network-policy-provider/weave-network-policy/#install-the-weave-net-addon

Next: [Kube API Server to Kubelet Connectivity](13-kube-apiserver-to-kubelet.md)

Previous: [Configuring Kubectl](11-configuring-kubectl.md)
