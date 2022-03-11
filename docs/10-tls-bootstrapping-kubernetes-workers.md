Previous: [Bootstrapping the Kubernetes Worker Nodes](09-bootstrapping-kubernetes-workers.md)

# TLS Bootstrapping Worker Nodes

If TLS bootstrapping does not work you can bootstrap the 2nd node the same way as the 1st one. In that case please go here: [Bootstrapping Kubernetes 2nd Worker](10b-optional-bootstrapping-kubernetes-worker-2.md)!!!

In the previous step we configured a worker node by
- Creating a set of key pairs for the worker node by ourself
- Getting them signed by the CA by ourself
- Creating a kube-config file using this certificate by ourself
- Everytime the certificate expires we must follow the same process of updating the certificate by ourself

This is not a practical approach when you have 1000s of nodes in the cluster, and nodes dynamically being added and removed from the cluster.  With TLS boostrapping:

- The Nodes can generate certificate key pairs by themselves
- The Nodes can generate certificate signing request by themselves
- The Nodes can submit the certificate signing request to the Kubernetes CA (Using the Certificates API)
- The Nodes can retrieve the signed certificate from the Kubernetes CA
- The Nodes can generate a kube-config file using this certificate by themselves
- The Nodes can start and join the cluster by themselves
- The Nodes can request new certificates via a CSR, but the CSR must be manually approved by a cluster administrator

In Kubernetes 1.11 a patch was merged to require administrator or Controller approval of node serving CSRs for security reasons.

Reference: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/#certificate-rotation

So let's get started!

# What is required for TLS Bootstrapping

**Certificates API:** The Certificate API (as discussed in the lecture) provides a set of APIs on Kubernetes that can help us manage certificates (Create CSR, Get them signed by CA, Retrieve signed certificate etc). The worker nodes (kubelets) have the ability to use this API to get certificates signed by the Kubernetes CA.

# Pre-Requisite

**kube-apiserver** - Ensure bootstrap token based authentication is enabled on the kube-apiserver.

`--enable-bootstrap-token-auth=true`

**kube-controller-manager** - The certificate requests are signed by the kube-controller-manager ultimately. The kube-controller-manager requires the CA Certificate and Key to perform these operations.

```
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.crt \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca.key
```

> Note: We have already configured these in our setup in this course

Copy the ca certificate to the worker node:


# On the 2nd worker node

### Download and Install Worker Binaries

```
KUBE_VERSION=`curl -L -s https://dl.k8s.io/release/stable.txt`
echo $KUBE_VERSION
cd /tmp

wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubelet
```

Reference: https://kubernetes.io/docs/setup/release/#node-binaries

### Create the installation directories:

```
worker-2$ sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

### Install the worker binaries:

```
{
  chmod +x kubectl kube-proxy kubelet
  sudo mv kubectl kube-proxy kubelet /usr/local/bin/
}
```
### Move the ca certificate
`sudo mv ca.crt /var/lib/kubernetes/`

# On master-1 or master-2 node
## Step 1 Create the Boostrap Token to be used by Nodes(Kubelets) to invoke Certificate API

For the workers(kubelet) to access the Certificates API, they need to authenticate to the kubernetes api-server first. For this we create a [Bootstrap Token](https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/) to be used by the kubelet

Bootstrap Tokens take the form of a 6 character token id followed by 16 character token secret separated by a dot. Eg: abcdef.0123456789abcdef. More formally, they must match the regular expression [a-z0-9]{6}\.[a-z0-9]{16}. In addition to this: These tokens are arbitrary but should represent at least 128 bits of entropy derived from a secure random number generator (such as /dev/urandom on most modern Linux systems). 

Generate expiration date of the token:
```
NEW_expiration_DATE=`date --rfc-3339=seconds -d "+365 days" | sed "s/ /T/"`
```

Generate and share the token:
```
TOKEN_ID=$(openssl rand -hex 3)
TOKEN_SECRET=$(openssl rand -hex 8)

cat > $HOME/CA/bootstrap-token.txt <<EOF
TOKEN_ID=${TOKEN_ID}
TOKEN_SECRET=${TOKEN_SECRET}
EOF
```

Add token to the cluster config:
```
cat > $HOME/CA/bootstrap-token-${TOKEN_ID}.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  # Name MUST be of form "bootstrap-token-<token id>"
  name: bootstrap-token-$TOKEN_ID
  namespace: kube-system

# Type MUST be 'bootstrap.kubernetes.io/token'
type: bootstrap.kubernetes.io/token
stringData:
  # Human readable description. Optional.
  description: "Manually generated bootstrap token."
  
  # Token ID and secret. Required.
  token-id: $TOKEN_ID
  token-secret: $TOKEN_SECRET

  usage-bootstrap-authentication: "true"
  usage-bootstrap-signing: "true"
  
  # Expiration. Optional.
  expiration: $NEW_expiration_DATE
  
  # Extra groups to authenticate the token as. Must start with "system:bootstrappers:"
  auth-extra-groups: system:bootstrappers:worker
EOF

kubectl create -f $HOME/CA/bootstrap-token-${TOKEN_ID}.yaml --kubeconfig=admin.kubeconfig
```

Things to note:
- **expiration** - make sure its set to a date in the future.
- **auth-extra-groups** - this is the group the worker nodes are part of. It must start with "system:bootstrappers:" This group does not exist already. This group is associated with this token.

Once this is created the token to be used for authentication is `07401b.f395accd246ae52d`

Reference: https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/#bootstrap-token-secret-format

## Step 2 Authorize workers(kubelets) to create CSR

Next we associate the group we created before to the system:node-bootstrapper ClusterRole. This ClusterRole gives the group enough permissions to bootstrap the kubelet

```
master-1$ kubectl create clusterrolebinding create-csrs-for-bootstrapping --clusterrole=system:node-bootstrapper --group=system:bootstrappers

--------------- OR ---------------

master-1$ cat > csrs-for-bootstrapping.yaml <<EOF
# enable bootstrapping nodes to create CSR
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: create-csrs-for-bootstrapping
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:node-bootstrapper
  apiGroup: rbac.authorization.k8s.io
EOF


master-1$ kubectl create -f csrs-for-bootstrapping.yaml

```
Reference: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/#authorize-kubelet-to-create-csr

## Step 3 Authorize workers(kubelets) to approve CSR
```
master-1$ kubectl create clusterrolebinding auto-approve-csrs-for-group --clusterrole=system:certificates.k8s.io:certificatesigningrequests:nodeclient --group=system:bootstrappers

 --------------- OR ---------------

master-1$ cat > auto-approve-csrs-for-group.yaml <<EOF
# Approve all CSRs for the group "system:bootstrappers"
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: auto-approve-csrs-for-group
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
  apiGroup: rbac.authorization.k8s.io
EOF


master-1$ kubectl create -f auto-approve-csrs-for-group.yaml
```

Reference: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/#approval

## Step 3 Authorize workers(kubelets) to Auto Renew Certificates on expiration

We now create the Cluster Role Binding required for the nodes to automatically renew the certificates on expiry. Note that we are NOT using the **system:bootstrappers** group here any more. Since by the renewal period, we believe the node would be bootstrapped and part of the cluster already. All nodes are part of the **system:nodes** group.

```
master-1$ kubectl create clusterrolebinding auto-approve-renewals-for-nodes --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeclient --group=system:nodes

--------------- OR ---------------

master-1$ cat > auto-approve-renewals-for-nodes.yaml <<EOF
# Approve renewal CSRs for the group "system:nodes"
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: auto-approve-renewals-for-nodes
subjects:
- kind: Group
  name: system:nodes
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
  apiGroup: rbac.authorization.k8s.io
EOF


master-1$ kubectl create -f auto-approve-renewals-for-nodes.yaml
```

Reference: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/#approval

# On 2nd worker node again
## Step 4 Configure Kubelet to TLS Bootstrap

It is now time to configure the second worker to TLS bootstrap using the token we generated

For worker-1 we started by creating a kubeconfig file with the TLS certificates that we manually generated.
Here, we don't have the certificates yet. So we cannot create a kubeconfig file. Instead we create a bootstrap-kubeconfig file with information about the token we created.

This is to be done on the `worker-2` node.

```
sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig set-cluster bootstrap --server='https://192.168.5.30:6443' --certificate-authority=/var/lib/kubernetes/ca.crt
sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig set-credentials kubelet-bootstrap --token=07401b.f395accd246ae52d
sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig set-context bootstrap --user=kubelet-bootstrap --cluster=bootstrap
sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig use-context bootstrap
```

Or

```
cat <<EOF | sudo tee /var/lib/kubelet/bootstrap-kubeconfig
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/ca.crt
    server: https://192.168.5.30:6443
  name: bootstrap
contexts:
- context:
    cluster: bootstrap
    user: kubelet-bootstrap
  name: bootstrap
current-context: bootstrap
kind: Config
preferences: {}
users:
- name: kubelet-bootstrap
  user:
    token: 07401b.f395accd246ae52d
EOF
```

Reference: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/#kubelet-configuration

## Step 5 Create Kubelet Config File

Create the `kubelet-config.yaml` configuration file:

```
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.crt"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.96.0.10"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
EOF
```

> Note: We are not specifying the certificate details - tlsCertFile and tlsPrivateKeyFile - in this file

## Step 6 Configure Kubelet Service

Create the `kubelet.service` systemd unit file:

```
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --bootstrap-kubeconfig="/var/lib/kubelet/bootstrap-kubeconfig" \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --cert-dir=/var/lib/kubelet/pki/ \\
  --rotate-certificates=true \\
  --rotate-server-certificates=true \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Things to note here:
- **bootstrap-kubeconfig**: Location of the bootstrap-kubeconfig file.
- **cert-dir**: The directory where the generated certificates are stored.
- **rotate-certificates**: Rotates client certificates when they expire.

## Step 7 Configure the Kubernetes Proxy

In one of the previous steps we created the kube-proxy.kubeconfig file. Check [here](https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md) if you missed it.

```
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
```

Create the `kube-proxy-config.yaml` configuration file:

```
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "192.168.5.0/24"
EOF
```

Create the `kube-proxy.service` systemd unit file:

```
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

## Step 8 Start the Worker Services

On worker-2:
```
{
  sudo systemctl daemon-reload
  sudo systemctl enable kubelet kube-proxy
  sudo systemctl start kubelet kube-proxy
}
```
> Remember to run the above commands on worker node: `worker-2`


# On master-1 node again
## Step 9 Approve Server CSR
Go to master-1 node (or any other place with admin kubectl config):
`kubectl get csr`

```
NAME        AGE   SIGNERNAME                                    REQUESTOR                 REQUESTEDDURATION   CONDITION
csr-k669g   3s    kubernetes.io/kubelet-serving                 system:node:worker-2      <none>              Pending
csr-ttdk9   11m   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:2d767d   <none>              Approved,Issued
csr-xqxq5   4s    kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:2d767d   <none>              Approved,Issued
```


Approve
select the one which is from worker-2 requestor and in pending state.

`kubectl certificate approve csr-k679g`

Note: In the event your cluster persists for longer than 365 days, you will need to manually approve the replacement CSR.

Reference: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/#kubectl-approval

## Verification

List the registered Kubernetes nodes from the master node:

```
kubectl get nodes --kubeconfig admin.kubeconfig
```

> output

```
NAME       STATUS   ROLES    AGE   VERSION
worker-1   NotReady   <none>   93s   v1.13.0
worker-2   NotReady   <none>   93s   v1.13.0
```
Note: It is OK for the worker node to be in a NotReady state. That is because we haven't configured Networking yet.

Next: [Configuring Kubectl](11-configuring-kubectl.md)

Previous: [Bootstrapping the Kubernetes Worker Nodes](09-bootstrapping-kubernetes-workers.md)
