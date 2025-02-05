provider "null" {}

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

# Télécharger l'ISO de Debian 12
wget https://cloud.debian.org/images/cloud/bookworm/20240211-1654/debian-12-genericcloud-amd64-20240211-1654.qcow2 -O /var/lib/vz/template/iso/debian-12-genericcloud-amd64-20240211-1654.qcow2

# Configurer les interfaces réseau
IFS=',' read -r -a networks <<< "$network_config"
qm set "$vm_id" --net0 virtio,bridge="${networks[0]},firewall=1"
qm set "$vm_id" --net1 virtio,bridge="${networks[1]},firewall=1"
qm set "$vm_id" --net2 virtio,bridge="${networks[2]},firewall=1"

# Activer CloudInit
qm set "$vm_id" --ide2 "$CLOUDINIT_DISK,media=cdrom"

# Ajouter l'ISO de Debian 12
qm set "$vm_id" --ide2 /var/lib/vz/template/iso/debian-12-genericcloud-amd64-20240211-1654.qcow2,media=cdrom

# Démarrer la VM clonée
qm start "$vm_id"
echo "VM $name clonée, ajoutée au pool '$POOL_NAME' et démarrée."
sleep 5

# Fonction pour appliquer un fichier Cloud-init spécifique
apply_cloudinit() {
    local vm_id=$1
    local cloudinit_file=$2
    local snippet_name=$(basename "$cloudinit_file")

    echo "Application du fichier Cloud-init pour la VM $vm_id"

    # Ajouter le fichier Cloud-init en tant que snippet
    add_cloudinit_snippet "$cloudinit_file"

    # Associer le fichier Cloud-init à la VM
    qm set "$vm_id" --cicustom "user=$SNIPPET_STORAGE:snippets/$snippet_name"

    # Redémarrer la VM pour appliquer Cloud-init
    qm stop "$vm_id"
    sleep 2
    qm start "$vm_id"

    echo "Cloud-init appliqué à la VM $vm_id."
}

# Création des VMs OPNsense en clonant le template, ajout au pool "pare-feu" et application de Cloud-init
for i in "${!OPNSENSE_VMS[@]}"; do
    clone_vm "${VM_IDS[$i]}" "${OPNSENSE_VMS[$i]}" "${NETWORK_CONFIGS[$i]}"
    apply_cloudinit "${VM_IDS[$i]}" "${CLOUDINIT_FILES[$i]}"
done

echo "Toutes les VMs OPNsense ont été clonées, ajoutées au pool '$POOL_NAME' et configurées avec Cloud-init."
