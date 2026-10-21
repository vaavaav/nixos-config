# Minecraft module

Everything needed to host Minecraft worlds on a machine: Docker, an isolated
network, the playit.gg tunnel, the `mc` command and nightly backups.

## Adding it to a machine

1. Add the module to the machine's `configuration.nix`:

   ```nix
   imports = [ ../../modules/minecraft ];
   ```

2. Rebuild:

   ```bash
   sudo nixos-rebuild switch --flake .#<machine>
   ```

3. Put the playit key on the machine (once; it is never stored in this repo):

   ```bash
   echo 'SECRET_KEY=...' | sudo tee /etc/playit/playit.env >/dev/null
   sudo chmod 600 /etc/playit/playit.env
   sudo systemctl restart docker-playit
   ```

4. Log out and back in, so your user picks up the `docker` group.

5. Create a world and host it:

   ```bash
   mc create survival
   mc host survival --ip 172.30.0.65
   mc whitelist survival add YourName
   ```

   Then point the playit tunnel at `172.30.0.65:25565`. `mc --help` lists every command.

6. Copy existing worlds and backups from the old machine, if any:
   `/srv/minecraft` and `/srv/minecraft-backups`.

## Removing it from a machine

Delete the import line and rebuild. Docker, the playit agent, the firewall rules,
the `mc` command and the backup timer all go away.

These stay on disk until you delete them yourself:

- `/srv/minecraft`
- `/srv/minecraft-backups`
- `/var/lib/docker`
- `/etc/playit`

## Files

| File | What it does |
| --- | --- |
| `mc.py` | The `mc` command |
| `settings.nix` | All settings: network, folders, backups, blocked ranges, playit version and key path |
| `docker.nix` | Docker, and your user in the `docker` group |
| `network.nix` | The Minecraft network and the firewall rules around it |
| `playit.nix` | The playit.gg agent |
| `mc.nix` | The `mc` command (passes the settings to `mc.py` as `MC_*` environment variables), its folders and the nightly backup |

## Day to day

- Check the next backup: `systemctl list-timers minecraft-backup`
- Back up now: `sudo systemctl start minecraft-backup`
- Check playit: `systemctl status docker-playit`
- See the settings in use: `mc config`
- List worlds: `mc list`
- Update playit: change the version in `settings.nix`, then rebuild

## Assumptions

- **NixOS firewall:** the machine uses the default iptables-based NixOS firewall
  (`networking.nftables.enable` stays `false`).
- **User:** the user (`zezocas`) is set in `settings.nix`. It owns the world and
  backup folders and is the same user (UID 1000) the Minecraft containers run as.
- **Docker group:** being in the `docker` group is as powerful as being root, so
  only your own user should be in it.
- **Home network ranges:** the home network, VPNs and Tailscale use
  `192.168.0.0/16`, `10.0.0.0/8` or `100.64.0.0/10`. These are blocked from the
  Minecraft network; change them in `settings.nix` if yours differ.
- **Subnet clash:** the subnet in `settings.nix` doesn't clash with any network the
  machine is on.
- **No open ports:** players connect through playit, so no ports are opened on
  the router or the machine's firewall.
- **Same-disk backups:** backups are on the same disk as the worlds, so they don't
  survive a dead disk. Copy them elsewhere if that matters.
