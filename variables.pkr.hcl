# ============== Connexion Proxmox ==============
variable "proxmox_url" {
  type        = string
  description = "URL de l'API Proxmox (ex: https://10.86.30.11:8006/api2/json)"
}

variable "proxmox_username" {
  type        = string
  description = "User Proxmox (ex: root@pam ou root@pve!packer-token)"
}

variable "skip_tls_verify" {
  type        = bool
  default     = false
  description = "Ignorer la vérification TLS (utile pour les certificats auto-signés)"
}

variable "packer_ip" {
  type        = string
  default     = ""
  description = "Adresse IP du serveur HTTP Packer pour le cloud-init. Laisser vide pour auto détection"
}
# ============== Paramètres du template ==============
variable "vm_name" {
  type        = string
  default     = "debian-13-template"
  description = "Nom de la VM à créer"
}

variable "meganode_template_id" {
  type    = number
  default = 9000
}

variable "supernode_template_id" {
  type    = number
  default = 9001
}

variable "mininode_template_id" {
  type    = number
  default = 9002
}

variable "cores" {
  type    = number
  default = 1
}

variable "memory" {
  type    = number
  default = 1024
}

variable "storage_pool" {
  type        = string
  default     = "local-ZFS"
  description = "Pool de stockage pour les disques de la VM"
}

variable "network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Bridge réseau à utiliser pour la VM"
}

variable "iso_file" {
  type        = string
  description = "Chemin ISO dans Proxmox"
}

variable "cloud_init_storage_pool" {
  type        = string
  default     = "local"
  description = "Pool de stockage pour le disque cloud-init"
}

variable "username" {
  type    = string
  default = "yoann"
}

variable "packages" {
  type        = string
  default     = "sudo qemu-guest-agent cloud-init"
  description = "Liste des packages à installer dans la VM (séparés par des espaces)"
}
