# Minecraft module

Everything needed to host Minecraft worlds on a machine: Docker, an isolated
network, the firewall rules that let players in over IPv6, the `mc` command and
nightly backups.

Players connect to the machine's public IPv6 address, so players without IPv6
can't connect.

## Adding it to a machine

1. Add the module to the machine's `configuration.nix`:

   ```nix
   imports = [ ../../modules/minecraft ];
   ```

2. List the ports players will use in `settings.nix` (`publicPorts`, one per
   world), then rebuild:

   ```bash
   sudo nixos-rebuild switch --flake .#<machine>
   ```

3. Log out and back in, so your user picks up the `docker` group.

4. Create a world and host it:

   ```bash
   mc create survival
   mc host survival --ip 172.30.0.65 --port 25565
   mc whitelist survival add YourName
   ```

   `mc --help` lists every command.

5. In the router's IPv6 firewall, allow TCP to this machine's stable IPv6
   address on the same ports as `publicPorts`. Find the address with
   `ip -6 addr show scope global` (the `mngtmpaddr` one, not `temporary`).

6. Players connect to `[YOUR_IPV6]:25565` (brackets included).

7. Copy existing worlds and backups from the old machine, if any:
   `/srv/minecraft` and `/srv/minecraft-backups`.

## Removing it from a machine

Delete the import line and rebuild. Docker, the firewall rules, the `mc` command
and the backup timer all go away. Close the ports in the router too.

These stay on disk until you delete them yourself:

- `/srv/minecraft`
- `/srv/minecraft-backups`
- `/var/lib/docker`

## Files

| File | What it does |
| --- | --- |
| `mc.py` | The `mc` command |
| `settings.nix` | All settings: bind address, public ports, network, folders, backups, blocked ranges |
| `docker.nix` | Docker, and your user in the `docker` group |
| `network.nix` | The Minecraft network and the firewall rules around it |
| `mc.nix` | The `mc` command (passes the settings to `mc.py` as `MC_*` environment variables), its folders and the nightly backup |

## Day to day

- Check the next backup: `systemctl list-timers minecraft-backup`
- Back up now: `sudo systemctl start minecraft-backup`
- See the settings in use: `mc config`
- List worlds: `mc list`
- Check what is listening: `sudo ss -tlnp | grep 2556`
- Check the open ports: `sudo ip6tables -L nixos-fw -n | grep dpt`

## Security

- Only the ports in `publicPorts` are open, and only over IPv6.
- Worlds start with online mode and the whitelist on. Keep them that way.
- RCON stays inside the container (`mc console` uses `docker exec`), so its
  port is never published.
- The worlds' network can't open connections to the home network, VPNs or
  Tailscale (`blockedRanges`), or to this machine.
- Your home IPv6 address is visible to every player. A DDoS against it takes
  down the whole home connection.

## Assumptions

- **NixOS firewall:** the machine uses the default iptables-based NixOS firewall
  (`networking.nftables.enable` stays `false`).
- **docker-proxy:** IPv6 reaches the IPv4-only containers through Docker's
  userland proxy (`userland-proxy`, set in `docker.nix`). Players therefore show
  up in the server logs as the network's gateway address, not their real IP, so
  IP bans don't work; use name bans and the whitelist.
- **User:** the user (`zezocas`) is set in `settings.nix`. It owns the world and
  backup folders and is the same user (UID 1000) the Minecraft containers run as.
- **Docker group:** being in the `docker` group is as powerful as being root, so
  only your own user should be in it.
- **Home network ranges:** the home network, VPNs and Tailscale use
  `192.168.0.0/16`, `10.0.0.0/8` or `100.64.0.0/10`. These are blocked from the
  Minecraft network; change them in `settings.nix` if yours differ.
- **Subnet clash:** the subnet in `settings.nix` doesn't clash with any network the
  machine is on.
- **Changing prefix:** the ISP can change the IPv6 prefix (for example after a
  router restart). Then the address players use changes, and the router rule
  must point to the new one.
- **Same-disk backups:** backups are on the same disk as the worlds, so they don't
  survive a dead disk. Copy them elsewhere if that matters.
