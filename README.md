# nixos-config

First, set the partition table. This will mount the partitions to `/mnt`:
```
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount hosts/<hostname>/disko.nix
```

Then, generate a default configuration for the host:
```
nixos-generate-config --root /mnt
```

Copy the generate configuration for the hardware to the host directory. You'll need to stage this file.
```
cp /etc/nixos/hardware-configuration.nix ./hosts/#<hostname>/
git add .
```

Finally, build the system:
```
nixos-rebuild switch --flake ./#<hostname>
# or nixos-install --flake ./#<hostname> if you are installing on a fresh system
```

and the home-manager configuration:
```
home-manager switch --flake ./#<username>
```

Whenever the version is updated:
```
sudo nix flake update
sudo nixos-rebuild switch --flake .#<hostname>
home-manager switch --flake .#<username>
```
