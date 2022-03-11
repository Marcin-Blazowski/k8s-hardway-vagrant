#!/bin/bash
HOSTNAME=$(hostname -s)
# 
## if [[ "$HOSTNAME" =~ "master-[0-9]" ]]
## then
  cd /tmp
  echo "Downloading kubectl ..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl
## fi
