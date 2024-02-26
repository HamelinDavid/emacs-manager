{ config, lib, ...}: with lib; {
  options.environment.variables = mkOption {
    type = with types; attrsOf str;
    default = {};
  };
  config.environment.before = foldlAttrs
    (ret: key: val: "export ${key}=\"${val}\"\n" + ret)
    ""
    config.environment.variables;
}