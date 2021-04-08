## Kubernetes Cluster using kubeadm

This repo guides you in setting up a kubernetes cluster with a master and worker node on Ubuntu 20.04 LTS.







### Prerequisites

[Installed KVM and libvirt](https://thenaim.com/posts/kvm-ubuntu/)



### Getting started

- #### Network configuration

  ```bash
  nano master/network-config.yml
  nano worker/network-config.yml
  ```

- #### Master node

  ```bash
cd master
./build.sh
  ```

- #### Worker node

  ```bash
cd worker &&\
./build.sh
  ```

- #### Join the cluster

  - Step1: Login to master node from terminal then run `cat kubeadm.token` and copy output.
  - Step2: Login to worker node from terminal paste copied token from master node and hit enter.

- #### kubectl

  - Dowload [kubectl](https://kubernetes.io/docs/tasks/tools/)

  - Copy `/etc/kubernetes/admin.conf` from master node and put into following path `~/.kube/config` of your local pc

    ```bash
    scp root@192.168.0.14:/etc/kubernetes/admin.conf ~/.kube/config
    ```

    



### Resource

- [An Introduction to Cloud-Config Scripting](https://www.digitalocean.com/community/tutorials/an-introduction-to-cloud-config-scripting)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/en/latest/)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)

