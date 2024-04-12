{ config, lib, ... }:

lib.mkIf config.networking.wireless.enable {
  networking.wireless.networks = {
    "@WOJO_UUID@" = {
      auth = ''
        eap=PEAP
        identity="@WOJO_USER@"
        password="@WOJO_PASS@"
      '';
      authProtocols = [ "WPA-EAP" ];
    };
  };
}
