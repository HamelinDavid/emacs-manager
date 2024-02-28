# top-level module
{lib, config, pkgs, epkgs, ...}:
with lib; {
  imports = [
    ./finputs.nix
    ./aux.nix
    ./variables.nix
  ];
  
  options = {
    environment = {
      before = mkOption {
        type = types.lines;
        description = "Commands to run before starting emacs";
        default = "";
      };

      after = mkOption {
        type = types.lines;
        description = "Commands to run after emacs stops";
        default = "";
      };

      packages = mkOption {
        type = with types; listOf package;
        default = [];
      };

      name = mkOption {
        type = types.str;
        description = "The name of the wrapper executable";
        default = "e";
      };
    };

    emacs = {
      config = mkOption {
        type = types.lines;
        description = "Emacs config";
        default = "";
      };

      package = mkOption {
        type = types.package;
        description = "The underlying emacs package";
        default = pkgs.emacs-gtk.override { withPgtk = true; };
      };

      packages = mkOption {
        type = with types; listOf package;
        description = "Emacs packages";
        default = [];
      };

      nix.enable = mkOption {
        type = types.bool;
        description = "Whether to enable nix-mode";
        default = true;
      };

      ui = {
        theme.zenburn.enable = mkOption {
          type = types.bool;
          description = "Whether to enable zenburn theme";
          default = true;
        };

        minimal = mkOption {
          type = types.bool;
          description = "Whether to disable emacs toolbar and menubar";
          default = true;
        };

        transparency = {
          enable = mkOption {
            type = types.bool; 
            description = "Whether to enable transparency in emacs";
            default = true;
          };
          key = mkOption {
            type = types.str;
            description = "Key used to toggle transparency in emacs";
            default = "M-<f9>";
          };
          value = mkOption {
            type = types.int;
            description = "How opaque the window should be when transparency is enabled";
            default = 72;
          };
          onStartup = mkOption {
            type = types.bool;
            description = "Whether the window should be transparent on startup";
            default = true;
          };
        };
      };

      fixCBack = mkOption {
        type = types.bool;
        description = "Makes C-h behave like C-Backspace. This is helpful when emacs is running in a terminal";
        default = true;
      };
    };
  };

  config = {
    emacs = {
      packages = with epkgs;
        (if config.emacs.ui.theme.zenburn.enable then [ zenburn-theme] else []) ++ 
        (if config.emacs.nix.enable then [ nix-mode] else []);
      config = 
        ''
        (setq inhibit-startup-message t) 
        (setq initial-scratch-message nil)
        '' + 
        (let cfg = config.emacs.ui.transparency; in if cfg.enable then
          ''
          (set-frame-parameter nil 'alpha-background ${toString (if cfg.onStartup then cfg.value else 100)})
          (defun kb/toggle-window-transparency ()
            "Toggle transparency."
            (interactive)
            (pcase (frame-parameter nil 'alpha-background)
              (${toString (cfg.value)} (set-frame-parameter nil 'alpha-background 100))
              (_ (set-frame-parameter nil 'alpha-background ${toString (cfg.value)}))
            )
          )
          (global-set-key (kbd "${cfg.key}") 'kb/toggle-window-transparency)
          ''
        else "") +
        (if config.emacs.ui.minimal then 
          ''
          (menu-bar-mode -1)
          (tool-bar-mode -1)
          ''
        else "") + 
        (if config.emacs.ui.theme.zenburn.enable then
          ''
          (load-theme 'zenburn t)
          ''
        else "") +
        (if config.emacs.fixCBack then
          ''
          (global-set-key (kbd "C-h") 'backward-kill-word)
          ''
        else "") +
        (if config.emacs.nix.enable then
          ''
          (require 'nix-mode)
          (add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-mode))
          ''
        else "")
        ;
      };

  };
}
