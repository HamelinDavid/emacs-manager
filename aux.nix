{ config, lib, ...}: with lib; let
  cfg = config.emacs.auxPath;
in {
  options.emacs.auxPath = mkOption {
    type = with types; nullOr str;
    description = "Where to put auxiliaries file (locks, autosave etc).";
    default = "~/.cache/emacs-aux";
  };

  config = {
    emacs.config = mkIf (cfg != null) ''
      (setq lock-file-name-transforms
        '(("\\`/.*/\\([^/]+\\)\\'" "${cfg}/locks/\\1" t)))
      (setq auto-save-file-name-transforms
        '(("\\`/.*/\\([^/]+\\)\\'" "${cfg}/autosave/\\1" t)))
      (setq backup-directory-alist
        '((".*" . "${cfg}/backup/")))
    '';

    environment.before = mkIf (cfg != null) ''
    aux="${replaceStrings ["~/"] ["$HOME/"] cfg}"
    mkdir -p "$aux/backup" "$aux/locks" "$aux/autosave"
    '';
  };
}