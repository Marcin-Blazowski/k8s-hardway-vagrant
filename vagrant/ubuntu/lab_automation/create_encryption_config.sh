#!/bin/bash
HOSTNAME=$(hostname -s)

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > /tmp/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

mkdir -p /var/lib/kubernetes/

# if this is master-1 then copy to target directory and shared folder
if [ "$HOSTNAME" == "master-1" ]
then
    cp /tmp/encryption-config.yaml $HOME/
    cp /tmp/encryption-config.yaml /vagrant/ubuntu/lab_automation/CA/
    exit 0
fi

# if on all other nodes then copy from shared folder
cp /vagrant/ubuntu/lab_automation/CA/encryption-config.yaml $HOME/
