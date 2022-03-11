#!/bin/bash
HOSTNAME=$(hostname -s)

cd $HOME

# if this is master-1 then generate and share
if [ "$HOSTNAME" == "master-1" ]
then
  LOADBALANCER_ADDRESS=192.168.5.30

  # Generate a kubeconfig file for the kube-proxy service:
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=https://${LOADBALANCER_ADDRESS}:6443 \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config set-credentials system:kube-proxy \
      --client-certificate=kube-proxy.crt \
      --client-key=kube-proxy.key \
      --embed-certs=true \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:kube-proxy \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
  }

  # Generate a kubeconfig file for the kube-controller-manager service:
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config set-credentials system:kube-controller-manager \
      --client-certificate=kube-controller-manager.crt \
      --client-key=kube-controller-manager.key \
      --embed-certs=true \
      --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:kube-controller-manager \
      --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
  }

  # Generate a kubeconfig file for the kube-scheduler service:
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config set-credentials system:kube-scheduler \
      --client-certificate=kube-scheduler.crt \
      --client-key=kube-scheduler.key \
      --embed-certs=true \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:kube-scheduler \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
  }

  # Generate a kubeconfig file for the admin user:
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=admin.kubeconfig

    kubectl config set-credentials admin \
      --client-certificate=admin.crt \
      --client-key=admin.key \
      --embed-certs=true \
      --kubeconfig=admin.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=admin \
      --kubeconfig=admin.kubeconfig

    kubectl config use-context default --kubeconfig=admin.kubeconfig
  }
  
  #Generate a kubeconfig file for the first worker node
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=https://${LOADBALANCER_ADDRESS}:6443 \
      --kubeconfig=worker-1.kubeconfig

    kubectl config set-credentials system:node:worker-1 \
      --client-certificate=worker-1.crt \
      --client-key=worker-1.key \
      --embed-certs=true \
      --kubeconfig=worker-1.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:node:worker-1 \
      --kubeconfig=worker-1.kubeconfig

    kubectl config use-context default --kubeconfig=worker-1.kubeconfig
  }

  #Generate a kubeconfig file for the second worker node.
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=https://${LOADBALANCER_ADDRESS}:6443 \
      --kubeconfig=worker-2.kubeconfig

    kubectl config set-credentials system:node:worker-2 \
      --client-certificate=worker-2.crt \
      --client-key=worker-2.key \
      --embed-certs=true \
      --kubeconfig=worker-2.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:node:worker-2 \
      --kubeconfig=worker-2.kubeconfig

    kubectl config use-context default --kubeconfig=worker-2.kubeconfig
  }

  mkdir -p /vagrant/ubuntu/lab_automation/kube_configs
  cp *.kubeconfig /vagrant/ubuntu/lab_automation/kube_configs/

  exit 0
fi

# Copy the appropriate kube-proxy kubeconfig files to each worker instance:
if [[ "$HOSTNAME" =~ worker-[0-9]* ]]
then
  cp /vagrant/ubuntu/lab_automation/kube_configs/kube-proxy.kubeconfig $HOME/
  cp /vagrant/ubuntu/lab_automation/kube_configs/worker-1.kubeconfig $HOME/
  cp /vagrant/ubuntu/lab_automation/kube_configs/worker-2.kubeconfig $HOME/
  exit 0
fi

# Copy the appropriate admin.kubeconfig, kube-controller-manager and kube-scheduler kubeconfig files to each controller instance:
if [[ "$HOSTNAME" =~ master-[2-9]* ]]
then
  cp /vagrant/ubuntu/lab_automation/kube_configs/*.kubeconfig $HOME/
  exit 0
fi