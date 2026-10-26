{
  description = "Templates Packer du homelab, environnement de développement et image de CI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs {
          inherit system;
          # Packer est sous BSL (non libre) : autorisé explicitement, et lui seul
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) ["packer"];
        }));

    # Outils communs au devShell et à l'image de CI
    Tools = pkgs:
      with pkgs; [
        packer # fmt et validate le code
        pre-commit
        gitleaks
        forgejo-runner
        ansible # utilisation de mes collections
        openbao # connexion Openbao dans .envrc
      ];
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages =
          Tools pkgs
          ++ [
            pkgs.skopeo # publication de l'image de CI
          ];
      };
    });

    packages = forAllSystems (pkgs: {
      # Image du job de CI
      ci-image = pkgs.dockerTools.buildLayeredImage {
        name = "packer-ci";
        contents =
          Tools pkgs
          ++ (with pkgs; [
            bashInteractive
            cacert
            coreutils
            curl
            dockerTools.fakeNss
            findutils
            gitMinimal
            gnugrep
            gnused
            gnutar
            gzip
            nodejs
            openssh
            which
          ]);
        extraCommands = ''
          mkdir -p tmp root
          chmod 1777 tmp
        '';
        config = {
          Env = [
            "PATH=/bin"
            "HOME=/root"
            "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            "LANG=C.UTF-8"
          ];
          WorkingDir = "/root";
        };
      };
    });
  };
}
