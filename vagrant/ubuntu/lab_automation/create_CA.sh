#!/bin/bash
HOSTNAME=$(hostname -s)

# if this is master-1 then generate and share
if [ "$HOSTNAME" == "master-1" ]
then
  mkdir -p $HOME/CA
  rm -f $HOME/CA/*
  cd $HOME/CA

  # Create private key for CA
  openssl genrsa -out ca.key 2048

  # tune openssl
  openssl rand -writerand $HOME/.rnd

  # Create CSR using the private key
  openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr

  # Self sign the csr using its own private key
  openssl x509 -req -in ca.csr -signkey ca.key -CAcreateserial -out ca.crt -days 1000

  # Generate private key for admin user
  openssl genrsa -out admin.key 2048

  # Generate CSR for admin user. Note the OU.
  openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr

  # Sign certificate for admin user using CA servers private key
  openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out admin.crt -days 1000

  # Generate the kube-controller-manager client certificate and private key
  openssl genrsa -out kube-controller-manager.key 2048
  openssl req -new -key kube-controller-manager.key \
    -subj "/CN=system:kube-controller-manager" -out kube-controller-manager.csr
  openssl x509 -req -in kube-controller-manager.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out kube-controller-manager.crt -days 1000

  #Generate the kube-proxy client certificate and private key
  openssl genrsa -out kube-proxy.key 2048
  openssl req -new -key kube-proxy.key \
    -subj "/CN=system:kube-proxy" -out kube-proxy.csr
  openssl x509 -req -in kube-proxy.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out kube-proxy.crt -days 1000

  # Generate the kube-scheduler client certificate and private key:
  openssl genrsa -out kube-scheduler.key 2048
  openssl req -new -key kube-scheduler.key \
    -subj "/CN=system:kube-scheduler" -out kube-scheduler.csr
  openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial  -out kube-scheduler.crt -days 1000

  # Generate certs for api-server
  cp /vagrant/ubuntu/lab_automation/openssl.cnf $HOME/CA/
  openssl genrsa -out kube-apiserver.key 2048
  openssl req -new -key kube-apiserver.key -subj "/CN=kube-apiserver" \
    -out kube-apiserver.csr -config $HOME/CA/openssl.cnf
  openssl x509 -req -in kube-apiserver.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out kube-apiserver.crt -extensions v3_req \
    -extfile openssl.cnf -days 1000

  # Generate certs for ETCD
  cp /vagrant/ubuntu/lab_automation/openssl-etcd.cnf $HOME/CA/
  openssl genrsa -out etcd-server.key 2048
  openssl req -new -key etcd-server.key -subj "/CN=etcd-server" \
    -out etcd-server.csr -config $HOME/CA/openssl-etcd.cnf
  openssl x509 -req -in etcd-server.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial  -out etcd-server.crt -extensions v3_req \
    -extfile openssl-etcd.cnf -days 1000

  # Generate the service-account certificate and private key:
  openssl genrsa -out service-account.key 2048
  openssl req -new -key service-account.key -subj "/CN=service-accounts" \
    -out service-account.csr
  openssl x509 -req -in service-account.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out service-account.crt -days 1000

  # enerate a certificate and private key for worker-1 node:
  cp /vagrant/ubuntu/lab_automation/openssl-worker-1.cnf $HOME/CA/
  openssl genrsa -out worker-1.key 2048
  openssl req -new -key worker-1.key -subj "/CN=system:node:worker-1/O=system:nodes" \
    -out worker-1.csr -config $HOME/CA/openssl-worker-1.cnf
  openssl x509 -req -in worker-1.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out worker-1.crt -extensions v3_req \
    -extfile $HOME/CA/openssl-worker-1.cnf -days 1000

  # enerate a certificate and private key for worker-2 node:
  cp /vagrant/ubuntu/lab_automation/openssl-worker-2.cnf $HOME/CA/
  openssl genrsa -out worker-2.key 2048
  openssl req -new -key worker-2.key -subj "/CN=system:node:worker-2/O=system:nodes" \
    -out worker-2.csr -config $HOME/CA/openssl-worker-2.cnf
  openssl x509 -req -in worker-2.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out worker-2.crt -extensions v3_req \
    -extfile $HOME/CA/openssl-worker-2.cnf -days 1000

  # copy to HOME dir
  cp $HOME/CA/*.crt $HOME/
  cp $HOME/CA/*.key $HOME/
  
  # copy to shared folder
  mkdir -p /vagrant/ubuntu/lab_automation/CA
  cp $HOME/CA/*.crt /vagrant/ubuntu/lab_automation/CA/
  cp $HOME/CA/*.key /vagrant/ubuntu/lab_automation/CA/

fi

# Copy the appropriate certificates and private keys to each controller instance:
cp /vagrant/ubuntu/lab_automation/CA/*.crt $HOME/
cp /vagrant/ubuntu/lab_automation/CA/*.key $HOME/