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

    # Outils des contrôles, communs au devShell et à l'image de CI
    checkTools = pkgs:
      with pkgs; [
        packer # fmt et validate le code
        pre-commit
        gitleaks
        forgejo-runner
      ];
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages =
          checkTools pkgs
          ++ [
            pkgs.openbao # connexion AppRole dans .envrc
            pkgs.skopeo # publication de l'image de CI
          ];
      };
    });

    packages = forAllSystems (pkgs: {
      # Image du job de CI
      ci-image = pkgs.dockerTools.buildLayeredImage {
        name = "packer-ci";
        contents =
          checkTools pkgs
          ++ (with pkgs; [
            bashInteractive
            coreutils
            findutils
            gnugrep
            gnused
            gnutar
            gzip
            which
            gitMinimal
            nodejs
            cacert
            dockerTools.fakeNss
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
          ];
          WorkingDir = "/root";
        };
      };
    });
  };
}
