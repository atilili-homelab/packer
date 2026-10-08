# Debian 13 Cloud-Init Template by Atilili

**Build Info:**
- Packer Version: ${packer_version}
- Build Date: ${build_date}

**Paquets Installés :**
${packages}

---

## 📦 Specs du Template

- **CPU:** 1 core
- **RAM:** 1 GB
- **Disk:** 10 GB (auto-resize au premier boot si agrandi)
- **OS:** Debian 13 (Trixie)

---

### 🐛 Troubleshooting
- **VM ne boot pas:** Vérifier les logs dans Console (Proxmox)
- **SSH refuse connexion:** Vérifier que cloud-init a terminé : `cloud-init status`
- **Disque pas resize:** Vérifier logs : `cat /var/log/cloud-init.log | grep -i grow`
