{ config, lib, ... }:

lib.mkIf config.networking.wireless.enable {
  networking.wireless.networks = {
    "La Casa" = {
      pskRaw = "ext:casa_psk";
    };

    "La Casa Rapida" = {
      pskRaw = "ext:casa_rapida_psk";
    };
  };
}
