{lib, ...}:
{
  # This is the best way I found to make flake inputs works with modules
  # Each module can add its inputs by importing an anonymous module adding the flakes
  # Problem is, because the module is not a file it might get included multiple times,
  # And the module system will complain because of re-definition
  # With a custom option type, we can allow re-definitions
  
  options.flakes = with lib; mkOption {
    type = mkOptionType {
      name = "flake input";
      merge = _: foldl (ret: x: ret // x.value) {};
    };
    default = {};
  };
}