{
  description = "Manage emacs with nix modules";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    systems = {
      url = "github:nix-systems/x86_64-linux";
      flake = false;
    };
  };

  outputs = {nixpkgs, systems, self, ...}@inputs: let
    lib = nixpkgs.lib;
    eachSystem = lib.genAttrs (import systems); 
  in with lib; {
    packages = eachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in with lib; rec {
      emacs-with-modules = pkgs.callPackage ({modules ? [], ...}: let 
        
        evaluated = evalModules {
          modules = modules ++ [
            ./top.nix
            {
              _module.args = {
                inherit (pkgs) system;
                inherit pkgs;
                inherit lib;
                epkgs = pkgs.emacsPackages;
              };
            }
          ];
        };

        config = evaluated.config;

        emacs = (pkgs.emacsPackagesFor config.emacs.package).emacsWithPackages (_: config.emacs.packages);
        configFile = pkgs.writeText "config.el" config.emacs.config;
        pstree = "${pkgs.pstree}/bin/pstree";
      in pkgs.writeShellApplication {
        name = config.environment.name;
        runtimeInputs = config.environment.packages;
        text = 
          ''
          ${config.environment.before}
          if [ -n "$(${pstree} -pp $$ -s "sshd")" ] || tty | grep -q "^/dev/tty[0-9]\\+$"; then
            "${emacs}/bin/emacs" -l "${configFile}" -nw "$@"
          else
            "${emacs}/bin/emacs" -l "${configFile}" "$@" 1>/dev/null 2>/dev/null & disown
          fi
          ${config.environment.after}
          '';
      }) {};
      default = emacs-with-modules;
    });
  };
}
