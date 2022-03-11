# Differences between original and this solution

Original: [Kubernetes the hard way on Vagrant](https://github.com/mmumshad/kubernetes-the-hard-way)

### 1. Latest versions (dynamic) of k8s components are installed.

### 2. Automation added to have all steps performed automatically by Vagrant shell provisioner.

3. Some minor fixes to align with latest versions of k8s.

4. Nice diagram with the k8s cluster architecture overview added.

5. Minor grammar fixes.

6. Tip for Vagrant and VirtualBox troubleshooting added.

7. Vagrant shared folder (/vagrant) is used to share data between VMs (nodes).

8. Separate lab to create worker-2 node manually added.

9. Some links to k8s docs updated.

10. Systemd logs review tips added.

11. Separate folder for CA files added on master-1 and /vagrant.

12. Token secret for TLS bootstrapping is generated (instead of a hardcoded one).

13. Some fixes for TLS bootstrapping (to align with latest version of k8s).

14. Dynamic kubelet configuration lab removed.
14. E2E tests removed.
16. Some not needed files removed.

## Differences between Mumshad's and Kelsey's solution

Platform: I use VirtualBox to setup a local cluster, the original one uses GCP

Nodes: 2 Master and 2 Worker vs 2 Master and 3 Worker nodes

Configure 1 worker node normally
and the second one with TLS bootstrap

Node Names: I use worker-1 worker-2 instead of worker-0 worker-1

IP Addresses: I use statically assigned IPs on private network

Certificate File Names: I use <name>.crt for public certificate and <name>.key for private key file. Whereas original one uses <name>-.pem for certificate and <name>-key.pem for private key.

I generate separate certificates for etcd-server instead of using kube-apiserver

Network:
We use weavenet

Add E2E Tests
