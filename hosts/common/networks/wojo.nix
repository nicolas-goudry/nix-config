{ config, lib, ... }:

lib.mkIf config.networking.wireless.enable {
  networking.wireless.networks = {
    "Wojo" = {
      auth = ''
        eap=PEAP
        identity="@WOJO_USER@"
        password="ext:wojo_pass"
      '';
      authProtocols = [ "WPA-EAP" ];
    };
  };
}
