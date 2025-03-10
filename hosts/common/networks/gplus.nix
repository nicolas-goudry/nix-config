{ config, lib, ... }:

lib.mkIf config.networking.wireless.enable {
  networking.wireless.networks = {
    "G.Plus" = {
      psk = "ext:gplus_psk";
    };
  };
}
