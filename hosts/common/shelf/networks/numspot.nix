{ config, lib, ... }:

lib.mkIf config.networking.wireless.enable {
  networking.wireless.networks = {
    "@NUMSPOT_UUID@" = {
      psk = "@NUMSPOT_PSK@";
    };
  };
}
