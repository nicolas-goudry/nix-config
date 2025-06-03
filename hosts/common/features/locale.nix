# References:
# - Locale
#   - https://wiki.nixos.org/wiki/Locales
#   - https://search.nixos.org/options?channel=unstable&query=i18n
#   - https://man.archlinux.org/man/locale.7
# - Time
#   - https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
{
  mkOptions =
    lib:
    let
      inherit (lib) mkOption types;
    in
    {
      language = mkOption {
        type = types.str;
        default = "en_US.UTF-8";
      };

      format = mkOption {
        type = types.str;
        default = "en_US.UTF-8";
      };

      timeZone = mkOption {
        type = types.nullOr types.str;
        # Defaults to UTC
        default = null;
      };
    };

  mkConfig =
    cfg:
    { lib, ... }:
    let
      inherit (lib) unique;
      inherit (cfg) format language timeZone;
    in
    {
      config = {
        time.timeZone = timeZone;

        i18n = {
          defaultLocale = language;

          supportedLocales = unique [
            "${language}/UTF-8"
            "${format}/UTF-8"
          ];

          extraLocaleSettings = {
            LC_ALL = language;
            LC_ADDRESS = format;
            LC_COLLATE = format;
            LC_CTYPE = language;
            LC_IDENTIFICATION = format;
            LC_MEASUREMENT = format;
            LC_MESSAGES = language;
            LC_MONETARY = format;
            LC_NAME = format;
            LC_NUMERIC = format;
            LC_PAPER = format;
            LC_TELEPHONE = format;
            LC_TIME = format;
          };
        };
      };
    };
}
