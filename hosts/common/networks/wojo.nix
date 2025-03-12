{ config, lib, ... }:

lib.mkIf config.networking.wireless.enable {
  networking.wireless.networks = {
    "Wojo" = {
      auth = ''
        eap=PEAP
        identity="@wojo_user@"
        password="ext:wojo_pass"
      '';
      authProtocols = [ "WPA-EAP" ];
    };
  };
}
