{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "suckbox";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.enable = true;
  services.xserver.windowManager.dwm.enable = true;
  services.xserver.displayManager.ly.enable = true;

  users.users.yourname = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
    git
    zsh
    qutebrowser
    neovim
    obsidian
    dmenu
    (st.overrideAttrs (old: {
      # optionally override st here if patched
    }))
  ];

  system.stateVersion = "24.05";
}
