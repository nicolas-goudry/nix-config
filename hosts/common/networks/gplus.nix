{ config, lib, ... }:

lib.mkIf config.networking.wireless.enable {
  networking.wireless.networks = {
    "G.Plus" = {
      pskRaw = "ext:gplus_psk";
    };
  };
}
