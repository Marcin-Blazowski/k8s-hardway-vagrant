Previous: [Compute resources](02-compute-resources.md)

# Installing the Client Tools

First identify a system from where you will perform administrative tasks, such as creating certificates, kubeconfig files and distributing them to the different VMs.

If you are on a Linux laptop, then your laptop could be this system. In my case I chose the master-1 node to perform administrative tasks. Whichever system you chose make sure that system is able to access all the provisioned VMs through SSH to copy files over.

Next steps of this tutorial assumes that you use master-1 VM to run administrative tasks if there is not any other place explicity mentioned.
The root user was used by me to run most of tasks. If you are not comfortable with this approach you probably know what you are doing, and you can use vagrant user on each VM for this.
You can run `sudo su -` as user vagrant to switch to user root.

## Access all VMs

Generate Key Pair on master-1 node.
Go to the folder with Vagrantfile and
```
vagrant ssh master-1
sudo su -
ssh-keygen
```
Leave all settings to default.
View the generated public key ID at:

```
cat $HOME/.ssh/id_rsa.pub
```

Copy public key to /vagrant (if you are on the master-1) to make it visible for all other nodes (VMs).
```
mkdir /vagrant/ssh
cat $HOME/.ssh/id_rsa.pub >> /vagrant/ssh/authorized_keys
```

Go to all VMs root user (or other user you want to use) and allow SSH key based authentication. Open another command line window and got to the Vagrantfile folder.

```
vagrant ssh <node-name>
sudo su -
cat /vagrant/ssh/authorized_keys >> ~/.ssh/authorized_keys
```

example:
```
vagrant ssh worker-1
sudo su -
cat /vagrant/ssh/authorized_keys >> ~/.ssh/authorized_keys
```

Repeat all of these steps for each and every VM (even on master-1 to allow master-1 to master-1 SSH communication).

## Install kubectl

The [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl). command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

Reference: [https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### Linux

```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
mv kubectl /tmp/
install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
rm /tmp/kubectl
```

### Verification

Verify `kubectl` version 1.23.4 or higher is installed:

```
kubectl version --client
```

> output should be something like below with the latest version number

```
Client Version: version.Info{Major:"1", Minor:"23", GitVersion:"v1.23.4", GitCommit:"e6c093d87ea4cbb530a7b2ae91e54c0842d8308a", GitTreeState:"clean", BuildDate:"2022-02-16T12:38:05Z", GoVersion:"go1.17.7", Compiler:"gc", Platform:"linux/amd64"}
```

Next: [Certificate Authority](04-certificate-authority.md)

Previous: [Compute resources](02-compute-resources.md)
