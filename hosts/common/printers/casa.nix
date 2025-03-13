{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf config.services.printing.enable {
  # Enable HP printers driver
  services.printing.drivers = [ pkgs.hplip ];

  # Configure printer
  hardware.printers.ensurePrinters = [
    {
      name = "Casa";
      location = "Home";
      deviceUri = "hp:/net/HP_OfficeJet_8010_series?ip=192.168.1.52";
      model = "drv:///hp/hpcups.drv/hp-officejet_8010_series.ppd";
    }
  ];
}
