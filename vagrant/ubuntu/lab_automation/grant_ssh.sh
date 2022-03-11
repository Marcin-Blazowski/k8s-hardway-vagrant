#!/bin/bash
HOSTNAME=$(hostname -s)
# generate key pair if on master-1 VM and copy to the shared folder
if [ "$HOSTNAME" = "master-1" ]
then
  rm -f $HOME/.ssh/id_rsa*
  ssh-keygen -f $HOME/.ssh/id_rsa -q -N ""
  mkdir -p /vagrant/ssh
  cat $HOME/.ssh/id_rsa.pub >> /vagrant/ssh/authorized_keys
fi

# authorize SSH access on all other nodes and master-1 itself
cat /vagrant/ssh/authorized_keys >> ~/.ssh/authorized_keys
