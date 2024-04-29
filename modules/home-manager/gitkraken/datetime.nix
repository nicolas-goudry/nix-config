{ lib }:

with lib;

let
  dateTimeLocales = [
    "af" # Afrikaans
    "sq" # Albanian
    "ar" # Arabic
    "ar-dz" # Arabic (Algeria)
    "ar-kw" # Arabic (Kuwait)
    "ar-ly" # Arabic (Libya)
    "ar-ma" # Arabic (Morocco)
    "ar-sa" # Arabic (Saudi Arabia)
    "ar-tn" # Arabic (Tunisia)
    "hy-am" # Armenian
    "az" # Azerbaijani
    "bm" # Bambara
    "eu" # Basque
    "be" # Belarusian
    "bn" # Bengali
    "bn-bd" # Bengali (Bangladesh)
    "bs" # Bosnian
    "br" # Breton
    "bg" # Bulgarian
    "my" # Burmese
    "km" # Cambodian
    "ca" # Catalan
    "tzm" # Central Atlas Tamazight
    "tzm-latn" # Central Atlas Tamazight Latin
    "zh-cn" # Chinese (China)
    "zh-hk" # Chinese (Hong Kong)
    "zh-mo" # Chinese (Macau)
    "zh-tw" # Chinese (Taiwan)
    "cv" # Chuvash
    "hr" # Croatian
    "cs" # Czech
    "da" # Danish
    "nl" # Dutch
    "nl-be" # Dutch (Belgium)
    "en" # English
    "en-au" # English (Australia)
    "en-ca" # English (Canada)
    "en-in" # English (India)
    "en-ie" # English (Ireland)
    "en-il" # English (Israel)
    "en-nz" # English (New Zealand)
    "en-sg" # English (Singapore)
    "en-gb" # English (United Kingdom)
    "en-us" # English (United States)
    "eo" # Esperanto
    "et" # Estonian
    "fo" # Faroese
    "fil" # Filipino
    "fi" # Finnish
    "fr" # French
    "fr-ca" # French (Canada)
    "fr-ch" # French (Switzerland)
    "fy" # Frisian
    "gl" # Galician
    "ka" # Georgian
    "de" # German
    "de-at" # German (Austria)
    "de-ch" # German (Switzerland)
    "el" # Greek
    "gu" # Gujarati
    "he" # Hebrew
    "hi" # Hindi
    "hu" # Hungarian
    "is" # Icelandic
    "id" # Indonesian
    "ga" # Irish or Irish Gaelic
    "it" # Italian
    "it-ch" # Italian (Switzerland)
    "ja" # Japanese
    "jv" # Javanese
    "kn" # Kannada
    "kk" # Kazakh
    "tlh" # Klingon
    "gom-deva" # Konkani Devanagari script
    "gom-latn" # Konkani Latin script
    "ko" # Korean
    "ku" # Kurdish
    "ky" # Kyrgyz
    "lo" # Lao
    "lv" # Latvian
    "lt" # Lithuanian
    "lb" # Luxembourgish
    "mk" # Macedonian
    "ms-my" # Malay
    "ms" # Malay
    "ml" # Malayalam
    "dv" # Maldivian
    "mt" # Maltese (Malta)
    "mi" # Maori
    "mr" # Marathi
    "mn" # Mongolian
    "me" # Montenegrin
    "ne" # Nepalese
    "se" # Northern Sami
    "nb" # Norwegian Bokm
    "nn" # Nynorsk
    "oc-lnc" # Occitan
    "fa" # Persian
    "pl" # Polish
    "pt" # Portuguese
    "pt-br" # Portuguese (Brazil)
    "pa-in" # Punjabi (India)
    "ro" # Romanian
    "ru" # Russian
    "gd" # Scottish Gaelic
    "sr" # Serbian
    "sr-cyrl" # Serbian Cyrillic
    "sd" # Sindhi
    "si" # Sinhalese
    "ss" # siSwati
    "sk" # Slovak
    "sl" # Slovenian
    "es" # Spanish
    "es-do" # Spanish (Dominican Republic)
    "es-mx" # Spanish (Mexico)
    "es-us" # Spanish (United States)
    "sw" # Swahili
    "sv" # Swedish
    "tl-ph" # Tagalog (Philippines)
    "tg" # Tajik
    "tzl" # Talossan
    "ta" # Tamil
    "te" # Telugu
    "tet" # Tetun Dili (East Timor)
    "th" # Thai
    "bo" # Tibetan
    "tr" # Turkish
    "tk" # Turkmen
    "uk" # Ukrainian
    "ur" # Urdu
    "ug-cn" # Uyghur (China)
    "uz" # Uzbek
    "uz-latn" # Uzbek Latin
    "vi" # Vietnamese
    "cy" # Welsh
    "yo" # Yoruba Nigeria
  ];
in
types.submodule {
  options = {
    format = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Date and time format as [Moment.js format string](https://momentjs.com/docs/#/displaying/format/).
      '';
    };

    locale = mkOption {
      type = types.nullOr (types.enum dateTimeLocales);
      default = null;
      description = ''
        Date/time locale. Set to `null` to use system default locale.
      '';
    };

    dateFormat = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Date format as [Moment.js format string](https://momentjs.com/docs/#/displaying/format/).
      '';
    };

    dateWordFormat = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Date word format as [Moment.js format string](https://momentjs.com/docs/#/displaying/format/).
      '';
    };

    dateVerboseFormat = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Verbose date format as [Moment.js format string](https://momentjs.com/docs/#/displaying/format/).
      '';
    };
  };
}
