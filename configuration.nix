# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./secrets.nix
    ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  networking.hostName = "babypool"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rwaugh = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
	screen
     ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     git
     zfs
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;
  services.dbus.enable = true;

  # ZFS
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "deadbeef";

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";  # Options: "daily", "weekly", etc.
    };
    autoSnapshot = {
      enable = true;
      frequent = 8;    # Keep last 8 frequent snapshots
      hourly = 24;     # Keep last 24 hourly snapshots
      daily = 7;       # Keep last 7 daily snapshots
      weekly = 4;      # Keep last 4 weekly snapshots
      monthly = 12;    # Keep last 12 monthly snapshots
    };
  };

  # Timemachine
  # Enable Samba service
  services.samba = {
    enable = true;
    settings = {
      "global" = {
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:aapl" = "yes";
        "logging" = "systemd";       # Use systemd for logging
        "log level" = "1";           # Minimal logging level
      };
    };
    # Define the Time Machine share
    settings = {
      "timemachine" = {
        path = "/tank/timemachine";   # Make sure this directory exists
        writable = true;
        browseable = false;
        "fruit:time machine" = "yes";
        "fruit:encoding" = "native";
        "fruit:locking" = "netatalk";
        "fruit:metadata" = "stream";
        "valid users" = [ "timemachine" ];
      };
    };
  };

  # Create Time Machine user
  users.users.timemachine = {
    isNormalUser = true;
    extraGroups = [ "users" ];
  };

  # Do not edit
  system.stateVersion = "24.11"; 
}

