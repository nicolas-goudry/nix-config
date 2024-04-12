{ config, lib, ... }:

lib.mkIf config.networking.wireless.enable {
  networking.wireless.networks = {
    "@GPLUS_UUID@" = {
      psk = "@GPLUS_PSK@";
    };
  };
}
