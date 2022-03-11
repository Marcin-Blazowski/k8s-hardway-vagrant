#!/bin/bash
HOSTNAME=$(hostname -s)

cp /vagrant/ubuntu/lab_automation/cluster_role_nodes.yaml $HOME/
cp /vagrant/ubuntu/lab_automation/cluster_role_binding_nodes.yaml $HOME/

kubectl apply -f $HOME/cluster_role_nodes.yaml
kubectl apply -f $HOME/cluster_role_binding_nodes.yaml


