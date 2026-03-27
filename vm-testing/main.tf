terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.2-rc03"
    }
  }
}

provider "proxmox" {
  pm_api_url = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "vm" {
  vmid        = 100
  name        = "testing"
  target_node = "bankwonosobo"
  
  clone       = "ubuntu-jammy" # The name of the template
  full_clone  = true
 
  agent       = 1
  cpu {
    cores = 2
    sockets = 2
  }
  memory      = 8192
  
  os_type = "cloud-init"
  # cloudinit_cdrom_storage = "local-lvm"

  bootdisk    = "scsi0"
  scsihw      = "virtio-scsi-pci"

  ipconfig0 = "ip=192.168.3.5/24,gw=192.168.3.1"

  ciuser = var.ci_user
  cipassword = var.ci_password
  sshkeys = file(var.ci_ssh_public_key)

  disks {
    scsi {
      scsi0 {
        # We have to specify the disk from our template, else Terraform will think it's not supposed to be there
        disk {
          storage = "local-lvm"
          # The size of the disk should be at least as big as the disk in the template. If it's smaller, the disk will be recreated
          size    = "100G" 
        }
      }
    }
    ide {
      # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
      ide1 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  lifecycle {
    ignore_changes = [ network ]
  }
}