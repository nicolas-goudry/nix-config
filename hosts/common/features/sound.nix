# References:
# - https://wiki.nixos.org/wiki/PipeWire
# - https://search.nixos.org/options?channel=unstable&query=services.pipewire
{ cfg, lib, ... }:

with lib;

{
  options = {
    enable = mkEnableOption "sound";

    airplay = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "AirPlay support";
          enableGlitchesFix = mkEnableOption "dropouts/glitches fix";
        };
      };

      default = {
        enable = false;
      };
    };
  };

  config = mkIf (cfg.enable) {
    # Disable PulseAudio
    # TODO: Replace with 'services.pulseaudio.enable' on 25.05
    hardware.pulseaudio.enable = false;

    # Enable RealtimeKit to acquire realtime scheduling priority for I/O threads
    security.rtkit.enable = true;

    # Force enable service discovery for AirPlay support
    services.avahi.enable = mkIf cfg.airplay.enable (mkForce true);

    # Configure PipeWire
    services.pipewire =
      {
        enable = true;

        # Enable ALSA support
        alsa.enable = true;
        alsa.support32Bit = true;

        # Enable PulseAudio server emulation
        pulse.enable = true;
      }
      // optionalAttrs cfg.airplay.enable {
        # Open UDP/6001-6002 (required by AirPlay for timing and control data)
        raopOpenFirewall = true;

        # Configure PipeWire for AirPlay support
        extraConfig.pipewire = {
          "10-airplay" = {
            "context.modules" = [
              {
                name = "libpipewire-module-raop-discover";

                # Increase buffer size to fix dropouts/glitches
                args = optionalAttrs cfg.airplay.enableGlitchesFix {
                  "raop.latency.ms" = 500;
                };
              }
            ];
          };
        };
      };
  };
}
