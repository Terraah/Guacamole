provider "proxmox" {
  pm_api_url      = "https://TON_IP_PROXMOX:8006/api2/json"
  pm_user         = "root@pam"
  pm_password     = var.pm_password
  pm_tls_insecure = true
}

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

  # Disque principal (correction ici)
  disk {
    type     = "scsi"
    storage  = "production"
    size     = "20G"
    format   = "raw"
  }

  disk {
    type    = "cloud-init"
    storage = "production"
  }

  # Configuration réseau
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  network {
    model  = "virtio"
    bridge = "vmbr2"
    tag    = 20
  }

  # Cloud-Init pour IP, DNS et accès SSH
  ciuser     = var.ci_user
  cipassword = var.ci_mdp
  sshkeys    = file(var.ssh_key_pub)

  ipconfig0  = "ip=172.16.0.50/24,gw=172.16.0.14"
  ipconfig1  = "ip=172.16.20.50/27,gw=172.16.20.30"

  searchdomain = "mynet.net"
  nameserver   = "172.16.20.29"

  # Suppression de depends_on sur proxmox_vm_qemu.reverse qui n'existe pas
}
