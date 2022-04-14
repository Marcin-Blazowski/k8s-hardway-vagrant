Previous: [Prerequisites](01-prerequisites.md)

# Provisioning Compute Resources

Note: You must have VirtualBox and Vagrant configured at this point.

Download this github repository and cd into the vagrant folder

`git clone https://github.com/Marcin-Blazowski/k8s-hardway-vagrant`

CD into vagrant directory

`cd k8s-hardway-vagrant\vagrant`

Run Vagrant up

`vagrant up`


This does the below:

- Deploys 5 VMs - 2 Master, 2 Worker and 1 Loadbalancer with the name 'kubernetes-ha-* '
    > This is the default settings. This can be changed at the top of the Vagrant file.
    > If you choose to change these settings, please also update vagrant/ubuntu/vagrant/setup-hosts.sh
    > to add the additional hosts to the /etc/hosts default before running "vagrant up".

- Review the architecture overview in the main chapter [K8s The Hard Way](../README.md)

- Sets IP addresses in the range 192.168.5

    | VM            |  VM Name               | Purpose       | IP           | Forwarded SSH Port   |
    | ------------  | ---------------------- |:-------------:| ------------:| ----------------:|
    | master-1      | kubernetes-ha-master-1 | Master        | 192.168.5.11 |     2711         |
    | master-2      | kubernetes-ha-master-2 | Master        | 192.168.5.12 |     2712         |
    | worker-1      | kubernetes-ha-worker-1 | Worker        | 192.168.5.21 |     2721         |
    | worker-2      | kubernetes-ha-worker-2 | Worker        | 192.168.5.22 |     2722         |
    | loadbalancer  | kubernetes-ha-lb       | LoadBalancer  | 192.168.5.30 |     2730         |

    > These are the default settings. These can be changed in the Vagrant file

- Adds a DNS entry to each of the nodes to access internet
    > DNS: 8.8.8.8 (this step is done by Vagrant)

- Installs Docker on Worker nodes (this is done by Vagrant on worker nodes)
- Runs the below command on all nodes to allow for network forwarding in IP Tables.
  This is required for kubernetes networking to function correctly.
    > sysctl net.bridge.bridge-nf-call-iptables=1 (this is also done by Vagrant on worker nodes)


## SSH to the nodes

There are two ways to SSH into the nodes:

### 1. SSH using Vagrant

  From the directory you ran the `vagrant up` command, run `vagrant ssh <vm>` for example `vagrant ssh master-1`. Then switch to root user (`sudo su -`)
  > Note: Use VM field from the above table and not the vm name itself.

### 2. SSH Using SSH Client Tools

Use your favourite SSH Terminal tool (putty).

Use the above IP addresses. Username and password based SSH is disabled by default.
Vagrant generates a private key for each of these VMs. It is placed under the .vagrant folder (in the directory you ran the `vagrant up` command from) at the below path for each VM:

**Private Key Path:** `.vagrant/machines/<machine name>/virtualbox/private_key`

**Username:** `vagrant`


## Verify Environment

- Ensure all VMs are up
- Ensure VMs are assigned the above IP addresses
- Ensure you can SSH into these VMs using the IP and private keys
- Ensure the VMs can ping each other
- Ensure the worker nodes have Docker installed on them.
  > command `sudo docker version`

## Troubleshooting Tips

#### 1. VM fails to provision
If any of the VMs failed to provision, or is not configured correct, delete the vm using the command:

`vagrant destroy <vm>`

Then reprovision. Only the missing VMs will be re-provisioned

`vagrant up`


Sometimes the delete does not delete the folder created for the vm and throws the below error.

VirtualBox error:

    VBoxManage.exe: error: Could not rename the directory 'D:\VirtualBox VMs\ubuntu-bionic-18.04-cloudimg-20190122_1552891552601_76806' to 'D:\VirtualBox VMs\kubernetes-ha-worker-2' to save the settings file (VERR_ALREADY_EXISTS)
    VBoxManage.exe: error: Details: code E_FAIL (0x80004005), component SessionMachine, interface IMachine, callee IUnknown
    VBoxManage.exe: error: Context: "SaveSettings()" at line 3105 of file VBoxManageModifyVM.cpp

Or error like this:
    ```
    There was an error while executing `VBoxManage`, a CLI used by Vagrant
    for controlling VirtualBox. The command and stderr is shown below.

    Command: ["import", "\\\\?\\C:\\Users\\UserName\\.vagrant.d\\boxes\\ubuntu-VAGRANTSLASH-bionic64\\20220117.0.0\\virtualbox\\box.ovf", "--vsys", "0", "--vmname", "ubuntu-bionic-18.04-cloudimg-20220117_1646390179788_92057", "--vsys", "0", "--unit", "13", "--disk", "C:/Users/UserName/VirtualBox VMs/ubuntu-bionic-18.04-cloudimg-20220117_1646390179788_92057/ubuntu-bionic-18.04-cloudimg.vmdk", "--vsys", "0", "--unit", "14", "--disk", "C:/Users/UserName/VirtualBox VMs/ubuntu-bionic-18.04-cloudimg-20220117_1646390179788_92057/ubuntu-bionic-18.04-cloudimg-configdrive.vmdk"]

    Stderr: 0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
    Interpreting \\?\C:\Users\UserName\.vagrant.d\boxes\ubuntu-VAGRANTSLASH-bionic64\20220117.0.0\virtualbox\box.ovf...
    OK.
    0%...
    Progress state: VBOX_E_FILE_ERROR
    VBoxManage.exe: error: Appliance import failed
    VBoxManage.exe: error: Machine settings file 'C:\Users\UserName\VirtualBox VMs\ubuntu-bionic-18.04-cloudimg-20220117_1646390179788_92057\ubuntu-bionic-18.04-cloudimg-20220117_1646390179788_92057.vbox' already exists
    VBoxManage.exe: error: Details: code VBOX_E_FILE_ERROR (0x80bb0004), component MachineWrap, interface IMachine
    VBoxManage.exe: error: Context: "enum RTEXITCODE __cdecl handleImportAppliance(struct HandlerArg *)" at line 1119 of file VBoxManageAppliance.cpp
    ```

In such cases delete the VM, then delete the VM folder and then re-provision

`vagrant destroy <vm>`

`rmdir "<path-to-vm-folder>\kubernetes-ha-worker-2"`

`vagrant up`

#### 2. Windows 10 host
If you have Windows 10 host: The 1st day I started all VMs were working fine. The next day some were slow, or very slow, and some were not responsive at all. The solution was to completely disable Hyper-V on my Windows 10 host. You have to do this in two places: official way and using the command line to set the "hypervisorlounchtype".

- Disable Hyper-V in Control Panel (Programs and Features -> Turn Windows features on or off -> Expand Hyper-V, expand Hyper-V Platform -> clear Hyper-V Hypervisor)
- Restart Windows.
- Run this as administrator (elevated command prompt): `bcdedit /set hypervisorlaunchtype off`.
- Restart Windows again.

Next: [Client tools](03-client-tools.md)

Previous: [Prerequisites](docs/01-prerequisites.md)