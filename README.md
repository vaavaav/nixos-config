# nixos-config

## Installation

Boot from a NixOS installer, partition and mount your disk to `/mnt`, then:

```bash
# Clone the repo
nix-shell -p git --run "git clone https://github.com/zezocas/nixos-config /mnt/etc/nixos"
cd /mnt/etc/nixos

# Generate and copy hardware config for the host
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/<hostname>/
git add hosts/<hostname>/hardware-configuration.nix

# Install
nixos-install --flake .#<hostname>
```

Available hosts: `E16`, `X260`, `pixa`, `cacete`

## Updating

```bash
sudo nix flake update
sudo nixos-rebuild switch --flake .#<hostname>
```

## Adding a new host

1. Create `hosts/<hostname>/configuration.nix` and `hosts/<hostname>/hardware-configuration.nix`
2. Register it in `flake.nix`:
   ```nix
   <hostname> = mkHost "<hostname>" [ "zezocas" ];
   ```
3. Run `nixos-rebuild switch --flake .#<hostname>`
