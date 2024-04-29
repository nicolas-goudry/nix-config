{ lib }:

with lib;

types.submodule {
  options = {
    enable = mkEnableOption "desktop notifications";

    feature = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Receive new features notifications.
      '';
    };

    help = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Receive help notifications.
      '';
    };

    marketing = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Receive marketing notifications. May not work without a
        paid subscription.
      '';
    };

    position = mkOption {
      type = types.enum [
        "top-left"
        "top-right"
        "bottom-left"
        "bottom-right"
      ];
      default = "bottom-left";
      description = ''
        Notification location within window.
      '';
    };

    system = mkOption {
      type = types.bool;
      default = true;
    };
  };
}
