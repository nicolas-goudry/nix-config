{ config, lib, ... }:

lib.mkIf config.networking.wireless.enable {
  networking.wireless.networks = {
    "La Casa" = {
      psk = "ext:casa_psk";
    };

    "La Casa Rapida" = {
      psk = "ext:casa_rapida_psk";
    };
  };
}
