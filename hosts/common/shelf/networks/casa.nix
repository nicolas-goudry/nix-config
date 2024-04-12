{ config, lib, ... }:

lib.mkIf config.networking.wireless.enable {
  networking.wireless.networks = {
    "@CASA_UUID@" = {
      psk = "@CASA_PSK@";
    };

    "@CASA_RAPIDA_UUID@" = {
      psk = "@CASA_RAPIDA_PSK@";
    };
  };
}
