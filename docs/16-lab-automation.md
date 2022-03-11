Previous: [Smoke Test](15-smoke-test.md)

# Lab automation

If you have some problems with labs and you want to make sure that it is going to work you can provision the whole kubernetes cluster automatically. I created a dedicated Vagrantfile to do this.

Steps below are for Windows hosts but you can tune this for Linux.

1. Create a backup copy of your Vagrantfile
`copy Vagrantfile Vagrantfile.backup`

2. Overwrite Vagrantfile with the lab automation one
`copy Vagrantfile.auto Vagrantfile`

3. Trigger VMs provisioning by Vagrant
`vagrant up`

You should get 5 VMs created with the k8s cluster provisioned by shell scripts.
The last step which should be also completed is responsible for smoke tests execution. Please review `vagrant up` output log.

You can also compare with the log stored [here](../vagrant/ubuntu/lab_automation/log/k8s-hard-way-vagrant-up-20220309.log).

Previous: [Smoke Test](15-smoke-test.md)