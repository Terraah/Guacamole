resource "proxmox_vm_qemu" "guaca" {
  name        = "guacamole"
  agent       = 1
  target_node = "horizon" 
  clone       = "debian.template"
  scsihw      = "virtio-scsi-pci"
  full_clone  = true

  # Configuration système
  vmid        = 5002
  cores       = 2
  memory      = 2048
  cpu         = "kvm64"
  os_type     = "cloud-init"
  tags        = "guacamole"
  pool        = "zone-relais"
  
  # Boot
  bootdisk    = "scsi0"

  # Disque principal
  disks {
    scsi {
      scsi0 {
        disk {
          size    = "20G"
          storage = "production"
          format  = "raw"
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = "production"
        }
      }
    }
  }

  # Configuration réseau
  network {
    model   = "virtio"  # Meilleur que e1000 pour les perfs
    bridge  = "vmbr0"   # LAN
  }

  network {
    model   = "virtio"
    bridge  = "vmbr2"   # VLAN20 - Service Interne
    tag     = "20"
  }

  # Cloud-Init pour IP, DNS et accès SSH
  ciuser     = var.ci_user
  cipassword = var.ci_mdp
  sshkeys    = file(var.ssh_key_pub)

  ipconfig0  = "ip=172.16.0.50/24,gw=172.16.0.14"
  ipconfig1  = "ip=172.16.20.50/27,gw=172.16.20.30"
  
  searchdomain = "mynet.net"
  nameserver   = "172.16.20.29"

  depends_on = [proxmox_vm_qemu.reverse]
}
