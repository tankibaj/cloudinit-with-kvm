

Spin up a virtual machine instance in a few seconds with [cloud image](https://cloud-images.ubuntu.com/) and [cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html) is a familiar practice on cloud platforms like AWS, GCP, and Azure. [Cloud image](https://cloud-images.ubuntu.com/) and [cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html) are not just for cloud providers, it can be deployed in KVM to spin up a virtual machine instantly without guest os installation.

The goal is to create a VM instance in KVM with [cloud image](https://cloud-images.ubuntu.com/) and [cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html).



### Prerequisites

[Installed KVM and libvirt](https://github.com/tankibaj/docs/blob/master/KVM-Ubuntu1804.md)



### Getting started

- ###### Update and install cloud image utils

  ```bash
  sudo apt update && sudo apt install -y cloud-image-utils
  ```

- ###### Cloud-Init configuration

  ```bash
  nano user-data.yml
  ```

- ###### Network configuration

  ```bash
  nano network-config.yml
  ```

- ###### Spin up VM

  ```bash
  bash CreateInstance.sh instance1 ubuntu 20 5902
  ```

 

### Resource

- [An Introduction to Cloud-Config Scripting](https://www.digitalocean.com/community/tutorials/an-introduction-to-cloud-config-scripting)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/en/latest/)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)