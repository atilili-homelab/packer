# PACKER

Templates de VM **Debian 13 (Trixie)** prêts pour cloud-init, construits avec
Packer sur mon cluster Proxmox VE de trois nœuds.

Ces templates sont la première partie de mon homelab : OpenTofu les clone pour
créer les VM, puis Ansible les configure plus finement.

## Ce que fait le build

Un seul `packer build` produit un template par nœud, en parallèle :

| Nœud      | VMID du template |
| --------- | ---------------- |
| meganode  | 9000             |
| supernode | 9001             |
| mininode  | 9002             |

Pour chaque nœud :

1. **Installation automatique** de Debian depuis l'ISO, pilotée par un fichier
   _preseed_ servi par Packer en HTTP (`preseed.cfg.pkrtpl`).
2. **Préparation** par `setup.sh.pkrtpl` : agent QEMU activé, mot de passe
   temporaire et sudo sans mot de passe supprimés, cloud-init remis à zéro,
   `machine-id` et clés SSH effacés, journaux vidés, espace libre mis à zéro
   pour un template plus compact.
3. **Conversion en template** Proxmox, avec une description générée
   (`template-description.md`) décrivant la version de Packer, la date du build
   et les paquets installés.

## Prérequis

- **Nix** avec les flakes activés, et **direnv**.
- **rbw** (client Bitwarden CLI) déverrouillé : il fournit les identifiants
  AppRole d'OpenBao.
- Un accès réseau à **OpenBao** et à l'**API Proxmox**.

Les outils (packer, pre-commit, gitleaks, client OpenBao) ne sont pas à
installer : ils sont fournis par le `flake.nix`, en versions figées par
`flake.lock`.

## Secrets

Aucun secret n'est stocké dans ce dépôt, ni sur disque.

- Le **token API Proxmox** et le **mot de passe temporaire du build** sont lus
  dans OpenBao grâce à la fonction `vault()` de Packer.
- À l'entrée dans le dossier, `.envrc` se connecte à OpenBao avec l'AppRole
  `packer` (identifiants lus dans Bitwarden via rbw) et exporte un token valable
  une heure, limité à la lecture de `secret/data/packer/*`.

## Utilisation

```bash
direnv allow            # une seule fois : charge l'environnement et le token OpenBao
packer init .           # télécharge le plugin Proxmox (version figée)
packer validate .       # vérifie que la configuration est bonne
packer build .          # build sur les trois nœuds (-only pour cibler)
packer build -force .   # pour forcer la recréation des templates
```

Les paramètres non secrets (URL de Proxmox, VMID, ressources, ISO, paquets) sont
dans `debian-13.auto.pkrvars.hcl`.

## Structure

| Fichier                      | Rôle                                                 |
| ---------------------------- | ---------------------------------------------------- |
| `debian-13-cloud.pkr.hcl`    | Source commune, variantes par nœud, secrets et build |
| `variables.pkr.hcl`          | Déclaration des variables                            |
| `debian-13.auto.pkrvars.hcl` | Valeurs des variables (non secrètes)                 |
| `preseed.cfg.pkrtpl`         | Réponses de l'installateur Debian                    |
| `setup.sh.pkrtpl`            | Préparation de la VM avant conversion en template    |
| `template-description.md`    | Modèle de la description affichée dans Proxmox       |
| `flake.nix`, `flake.lock`    | Environnement de développement reproductible         |
| `.envrc`                     | Chargement de l'environnement et connexion à OpenBao |
| `.pre-commit-config.yaml`    | Contrôles automatiques avant chaque commit           |

## Licence

[MIT](LICENSE)
