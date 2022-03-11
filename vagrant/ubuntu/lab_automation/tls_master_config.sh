#!/bin/bash

HOSTNAME=$(hostname -s)

# Run this only on master-2
if [ "$HOSTNAME" != "master-2" ]
then
  echo "This is not master-2. Exiting."
  exit 0
fi

# Generate token
NEW_expiration_DATE=`date --rfc-3339=seconds -d "+365 days" | sed "s/ /T/"`

TOKEN_ID=$(openssl rand -hex 3)
TOKEN_SECRET=$(openssl rand -hex 8)

mkdir -p $HOME/CA

cat > $HOME/CA/bootstrap-token.txt <<EOF
TOKEN_ID=${TOKEN_ID}
TOKEN_SECRET=${TOKEN_SECRET}
EOF

# share the token
cp $HOME/CA/bootstrap-token.txt /vagrant/ubuntu/lab_automation/CA/

cd $HOME

# Add token to the cluster config
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

# Authorize workers(kubelets) to create CSR
cat > csrs-for-bootstrapping.yaml <<EOF
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

kubectl create -f csrs-for-bootstrapping.yaml --kubeconfig=admin.kubeconfig

# Authorize workers(kubelets) to approve CSR
cat > auto-approve-csrs-for-group.yaml <<EOF
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

kubectl create -f auto-approve-csrs-for-group.yaml --kubeconfig=admin.kubeconfig

# Authorize workers(kubelets) to Auto Renew Certificates on expiration
cat > auto-approve-renewals-for-nodes.yaml <<EOF
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

kubectl create -f auto-approve-renewals-for-nodes.yaml --kubeconfig=admin.kubeconfig