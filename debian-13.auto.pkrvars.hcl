#=== Proxmox Packer Template Variables ===
proxmox_url      = "http://10.86.30.10:8006/api2/json"
proxmox_username = "root@pam!packer"
skip_tls_verify  = true

#=== Template Configuration ===
vm_name               = "debian-13-template"
meganode_template_id  = 9000
supernode_template_id = 9001
mininode_template_id  = 9002

cores          = 1
memory         = 1024
storage_pool   = "local-ZFS"
network_bridge = "vmbr0"

iso_file = "nas-ressources:iso/debian-13.5.0-amd64-netinst.iso"
username = "yoann"

packages = "sudo qemu-guest-agent cloud-init python3 python3-apt curl wget ca-certificates nfs-common"
