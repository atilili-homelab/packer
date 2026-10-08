packer {
  required_plugins {
    proxmox = {
      version = "= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# ── Secrets lus dans OpenBao (VAULT_ADDR et VAULT_TOKEN fournis par .envrc) ──
local "proxmox_token" {
  expression = vault("/secret/data/packer/proxmox", "token")
  sensitive  = true
}

local "build_password" {
  expression = vault("/secret/data/packer/proxmox", "build_password")
  sensitive  = true
}

locals {
  preseed_http_ip = var.packer_ip != "" ? var.packer_ip : "{{ .HTTPIP }}"

  # Caractéristiques du disque, communes aux trois nœuds (seul le stockage change)
  disk = {
    type      = "scsi"
    disk_size = "10G"
    format    = "raw"
  }
}

# ── Source de base : tout ce qui est commun aux trois nœuds ──
# Les variantes (nœud, VMID, disque) sont déclarées dans le bloc build.
source "proxmox-iso" "debian-13" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = local.proxmox_token
  insecure_skip_tls_verify = var.skip_tls_verify
  vm_name                  = var.vm_name
  template_description = templatefile("${path.root}/template-description.md", {
    packer_version = packer.version
    build_date     = formatdate("DD-MM-YYYY", timestamp())
    packages       = var.packages
  })

  # ── Onglet "OS" ──
  boot_iso {
    iso_file = var.iso_file
    unmount  = true
  }
  os = "l26"

  # ── Onglet "General" ──
  scsi_controller = "virtio-scsi-single"
  qemu_agent      = true

  # ── Onglets "CPU" et "Memory" ──
  cores   = var.cores
  sockets = 1
  memory  = var.memory

  # ── Onglet "Network" ──
  network_adapters {
    model  = "virtio"
    bridge = var.network_bridge
  }

  # ── Onglet "Hard Disk" : déclaré dans chaque variante du bloc build ──

  # ── Cloud-init ──
  cloud_init              = true
  cloud_init_storage_pool = var.cloud_init_storage_pool

  # ── Preseed : installation automatique ──
  # Plage de ports fixe, ouverte dans le pare-feu du poste qui lance le build
  http_port_min = 8800
  http_port_max = 8810
  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/preseed.cfg.pkrtpl", {
      username    = var.username
      password    = local.build_password
      packages    = var.packages
      vm_hostname = var.vm_name
    })
  }
  boot_wait = "10s" # attendre 10s que l'ISO boot
  boot_command = [
    "<esc><wait>",
    "install ",
    "preseed/url=http://${local.preseed_http_ip}:{{ .HTTPPort }}/preseed.cfg ",
    "locale=fr_FR.UTF-8 ",
    "keyboard-configuration/xkb-keymap=fr ",
    "netcfg/get_hostname=${var.vm_name} ",
    "netcfg/get_domain= ",
    "fb=false ",
    "auto=true ",
    "priority=critical",
    "<enter>"
  ]

  # ── Connexion SSH (pour les provisioners) ──
  ssh_username = var.username
  ssh_password = local.build_password
  ssh_timeout  = "20m" # timeout si l'install est longue
}

build {
  # Une variante par nœud : seuls le nœud, le VMID et le stockage du disque changent.
  # Le bloc disks est déclaré ici et non dans la source de base, pour éviter
  # toute ambiguïté de fusion entre un bloc de base et un bloc surchargé.
  source "proxmox-iso.debian-13" {
    name  = "meganode"
    node  = "meganode"
    vm_id = var.meganode_template_id
    disks {
      type         = local.disk.type
      storage_pool = var.storage_pool
      disk_size    = local.disk.disk_size
      format       = local.disk.format
    }
  }

  source "proxmox-iso.debian-13" {
    name  = "supernode"
    node  = "supernode"
    vm_id = var.supernode_template_id
    disks {
      type         = local.disk.type
      storage_pool = var.storage_pool
      disk_size    = local.disk.disk_size
      format       = local.disk.format
    }
  }

  source "proxmox-iso.debian-13" {
    name  = "mininode"
    node  = "mininode"
    vm_id = var.mininode_template_id
    disks {
      type         = local.disk.type
      storage_pool = "local-LVM" # mininode n'a pas de ZFS
      disk_size    = local.disk.disk_size
      format       = local.disk.format
    }
  }

  provisioner "shell" {
    inline = [templatefile("${path.root}/setup.sh.pkrtpl", {
      username = var.username
    })]
  }
}
