

Spin up a virtual machine instance in a few seconds with [cloud image](https://cloud-images.ubuntu.com/) and [cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html) is a familiar practice on cloud platforms like AWS, GCP, and Azure. [Cloud image](https://cloud-images.ubuntu.com/) and [cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html) are not just for cloud providers, it can be deployed in KVM to spin up a virtual machine instantly without guest os installation.

The goal is to create a jenkins instance in KVM with [cloud image](https://cloud-images.ubuntu.com/) and [cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html).



### Prerequisites

[Installed KVM and libvirt](https://thenaim.com/posts/kvm-ubuntu/)



### Getting started

- ###### Cloud-Init configuration

  ```bash
  nano user-data.yml
  ```

- ###### Network configuration

  ```bash
  nano network-config.yml
  ```

- ###### Spin up jenkins instance

  ```bash
  ./build.sh
  ```

 

### Resource

- [An Introduction to Cloud-Config Scripting](https://www.digitalocean.com/community/tutorials/an-introduction-to-cloud-config-scripting)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/en/latest/)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
