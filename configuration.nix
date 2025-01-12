# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  secrets = import ./secrets.nix;
  sambaUsers = lib.listToAttrs (map (user: {
    name = user.username;
    value = {
      isNormalUser = true;
      extraGroups = [ "users" ];
      password = user.password;
    };
  }) secrets.sambaUsers);
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
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
  users.users = {
    rwaugh = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      packages = with pkgs; [ screen ];
    };
  } // sambaUsers;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     git
     zfs
     jq
     parted
     lsof
     psmisc
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
  # networking.firewall.allowedTCPPorts = [ 137 138 139 445 ];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;
  services.dbus.enable = true;
  
  # ZFS
  boot.zfs.package = pkgs.zfs_unstable;
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
    openFirewall = true;
    settings = {
      global = {
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:aapl" = "yes";
        "logging" = "systemd";       # Use systemd for logging
        "log level" = "2";           # Minimal logging level
        "security" = "user";
        "map to guest" = "Bad User";
        "netbios name" = "babypool";
        "name resolve order" = "wins bcast host";
        "passdb backend" = "tdbsam";
      };
      timemachine = {
        path = "/tank/timemachine";   
        writable = true;
        browseable = true;
        "fruit:time machine" = "yes";
        "fruit:encoding" = "native";
        "fruit:locking" = "netatalk";
        "fruit:metadata" = "stream";
        "valid users" = [ "timemachine" ];
      };
      backup = {
        path = "/tank/backup ";   
        writable = true;
        browseable = true;
        "valid users" = [ "backup" ];
      };
    };
  };  

  system.activationScripts.addSambaUsers = {
    text = ''
      for user in ${lib.concatStringsSep " " (map (u: u.username) secrets.sambaUsers)}; do
        # Find the corresponding password for each user in the secrets array
        password=$(${pkgs.jq}/bin/jq -r ".sambaUsers[] | select(.username == \"$user\") | .password" <<<'${builtins.toJSON secrets}')

        # Add user to Samba passdb if not already present
        if ! ${pkgs.samba}/bin/pdbedit -L | grep -q "^$user:"; then
          echo -e "$password\n$password" | ${pkgs.samba}/bin/smbpasswd -a -s "$user"
        fi
      done
    '';
  };
  # Do not edit
  system.stateVersion = "24.11"; 
}

