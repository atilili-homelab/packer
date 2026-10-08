{
  description = "Templates Packer du homelab — environnement de développement";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs {
          inherit system;
          # Packer est sous BSL (non libre) : autorisé explicitement, et lui seul
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) ["packer"];
        }));
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          packer
          pre-commit
          gitleaks
          openbao # connexion AppRole dans .envrc
        ];
      };
    });

    formatter = forAllSystems (pkgs: pkgs.alejandra);
  };
}
