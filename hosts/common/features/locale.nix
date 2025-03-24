# References:
# - Locale
#   - https://wiki.nixos.org/wiki/Locales
#   - https://search.nixos.org/options?channel=unstable&query=i18n
#   - https://man.archlinux.org/man/locale.7
# - Time
#   - https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
{ cfg, lib, ... }:

with lib;

{
  options = {
    language = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
    };

    format = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
    };

    timeZone = mkOption {
      type = types.nullOr str;
      # Default to UTC
      default = null;
    };
  };

  config = {
    time.timeZone = cfg.timeZone;

    i18n = {
      defaultLocale = cfg.language;

      i18n.supportedLocales = unique [ "${cfg.language}/UTF-8" "${cfg.format}/UTF-8" ];

      extraLocaleSettings = {
        LC_ALL = cfg.language;
        LC_ADDRESS = cfg.format;
        LC_COLLATE = cfg.format;
        LC_CTYPE = cfg.language;
        LC_IDENTIFICATION = cfg.format;
        LC_MEASUREMENT = cfg.format;
        LC_MESSAGES = cfg.language;
        LC_MONETARY = cfg.format;
        LC_NAME = cfg.format;
        LC_NUMERIC = cfg.format;
        LC_PAPER = cfg.format;
        LC_TELEPHONE = cfg.format;
        LC_TIME = cfg.format;
      };
    };
  };
}
