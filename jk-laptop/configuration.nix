{ ... }: {
  networking.hostName = "jk-laptop";
  imports = [ ./hardware-configuration.nix ];

  hardware.enableRedistributableFirmware = true;

  system.stateVersion = "26.05";
}
