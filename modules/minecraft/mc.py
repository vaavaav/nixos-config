#!/usr/bin/env python3
"""
mc.py - run Minecraft servers ("worlds") in Docker, one container per world.

Worlds:     create, host, unhost, rename, start, stop, restart, set, upgrade, restore
Players:    whitelist, op, console, cmd, logs
Backups:    backup, schedule-backups
Overview:   list, config

Run ./mc.py COMMAND --help for the options of each command.
Settings (paths, Docker network, defaults, backup schedule) live in mc.env.
"""

import argparse
import gzip
import ipaddress
import json
import os
import pwd
import re
import shutil
import struct
import subprocess
import sys
import tarfile
import tempfile
import time
from datetime import datetime
from pathlib import Path

# ════════════════════════════════════════════════════════════════════════
# Settings (mc.env)
#   Order of precedence: environment variable > mc.env > defaults below.
#   An empty value means "use the default".
# ════════════════════════════════════════════════════════════════════════

SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_FILE = Path(os.environ.get("MC_CONFIG") or SCRIPT_DIR / "mc.env")

SETTING_DEFAULTS = {
    "MC_IMAGE": "itzg/minecraft-server",
    "MC_DATA_ROOT": "",  # empty: your home folder
    "MC_BACKUP_DIR": "",  # empty: ./backups next to mc.py
    "MC_NETWORK": "mcnet",
    "MC_NETWORK_SUBNET": "172.30.0.0/24",
    "MC_NETWORK_BRIDGE": "br-mc",
    "MC_DEFAULT_BIND": "127.0.0.1",
    "MC_DEFAULT_MEMORY": "6G",
    "MC_BACKUP_TIME": "04:00",
    "MC_BACKUP_KEEP": "7",
}


def settings_error(msg):
    print(f"Error in settings ({CONFIG_FILE}): {msg}", file=sys.stderr)
    sys.exit(1)


def load_settings():
    from_file = {}
    if CONFIG_FILE.is_file():
        line_re = re.compile(r"\s*([A-Z_][A-Z0-9_]*)=\s*(.*?)\s*")
        for n, line in enumerate(CONFIG_FILE.read_text().splitlines(), 1):
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            m = line_re.fullmatch(line)
            if not m:
                print(
                    f"Warning: {CONFIG_FILE}:{n}: ignored, expected KEY=value "
                    f"(no spaces around '=')",
                    file=sys.stderr,
                )
                continue
            key, value = m.groups()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                value = value[1:-1]
            if key not in SETTING_DEFAULTS:
                print(
                    f"Warning: {CONFIG_FILE}:{n}: unknown setting {key} (typo?)",
                    file=sys.stderr,
                )
            from_file[key] = value
    return {
        k: os.environ.get(k) or from_file.get(k) or default
        for k, default in SETTING_DEFAULTS.items()
    }


def user_home():
    """The real user's home, also under sudo or when run as root by the backup job."""
    if os.environ.get("SUDO_USER"):
        return Path(os.path.expanduser("~" + os.environ["SUDO_USER"]))
    if os.geteuid() == 0:
        try:
            owner = pwd.getpwuid(Path(__file__).resolve().stat().st_uid)
            if owner.pw_uid != 0:
                return Path(owner.pw_dir)
        except (KeyError, OSError):
            pass
    return Path.home()


def settings_path(value, default):
    """A path from mc.env: '~' is the user's home, relative paths are next to mc.py."""
    if not value:
        return default
    if value.startswith("~"):
        value = str(HOME) + value[1:]
    path = Path(value)
    return path if path.is_absolute() else SCRIPT_DIR / path


SETTINGS = load_settings()
HOME = user_home()

IMAGE = SETTINGS["MC_IMAGE"]
DATA_ROOT = settings_path(SETTINGS["MC_DATA_ROOT"], HOME)
BACKUP_DIR = settings_path(SETTINGS["MC_BACKUP_DIR"], SCRIPT_DIR / "backups")
NETWORK = SETTINGS["MC_NETWORK"]
NETWORK_SUBNET = SETTINGS["MC_NETWORK_SUBNET"]
NETWORK_BRIDGE = SETTINGS["MC_NETWORK_BRIDGE"]
DEFAULT_BIND = SETTINGS["MC_DEFAULT_BIND"]
DEFAULT_MEMORY = SETTINGS["MC_DEFAULT_MEMORY"]
BACKUP_TIME = SETTINGS["MC_BACKUP_TIME"]

try:
    EXAMPLE_IP = str(ipaddress.ip_network(NETWORK_SUBNET).network_address + 65)
except ValueError as e:
    settings_error(str(e))
if len(NETWORK_BRIDGE) > 15:
    settings_error(
        f"MC_NETWORK_BRIDGE '{NETWORK_BRIDGE}' is longer than 15 characters "
        f"(the Linux limit for network interface names)."
    )
try:
    BACKUP_KEEP = int(SETTINGS["MC_BACKUP_KEEP"])
except ValueError:
    settings_error(
        f"MC_BACKUP_KEEP must be a number, not '{SETTINGS['MC_BACKUP_KEEP']}'."
    )


# ════════════════════════════════════════════════════════════════════════
# Constants
# ════════════════════════════════════════════════════════════════════════

CONTAINER_PORT = 25565

# Server settings passed to the container, read back on upgrade/set/--replace.
MANAGED_KEYS = (
    "TYPE",
    "VERSION",
    "MEMORY",
    "ONLINE_MODE",
    "SEED",
    "MODE",
    "FORCE_GAMEMODE",
    "LEVEL_TYPE",
    "ENABLE_WHITELIST",
    "ENFORCE_WHITELIST",
)

LABEL = "mc.py.role"  # "world" on hosted worlds, "create" on temporary ones
MARKER = ".mc-py.json"  # in each world folder: remembers its type and image

GAME_MODES = ("survival", "creative", "adventure")
MODDED_EXAMPLES = "FABRIC, FORGE, NEOFORGE or QUILT"
OLD_JAVA_TAGS = ("java8", "java11", "java16", "java17")

NAME_RE = re.compile(r"[a-zA-Z0-9][a-zA-Z0-9_.-]*")
BACKUP_NAME_SUFFIX_RE = re.compile(r"-\d{8}-\d{6}(-pre-upgrade)?$")
BACKUP_EXCLUDES = ("cache", "libraries", "versions", ".rcon-cli.env", ".rcon-cli.yaml")

CREATE_TIMEOUT = 15 * 60
CREATE_POLL = float(os.environ.get("MC_CREATE_POLL", "3"))
STOP_TIMEOUT = "120"

SYSTEMD_DIR = Path(os.environ.get("MC_SYSTEMD_DIR") or "/etc/systemd/system")
SYSTEMD_RUNNING = Path("/run/systemd/system").is_dir() or "MC_SYSTEMD_DIR" in os.environ
BACKUP_UNIT = "mc-backup"


# ════════════════════════════════════════════════════════════════════════
# Shell helpers
# ════════════════════════════════════════════════════════════════════════


def die(msg):
    print(f"Error: {msg}", file=sys.stderr)
    sys.exit(1)


_docker_prefix = None


def sudo_prefix():
    """[] if this user can use Docker directly, otherwise ['sudo']."""
    global _docker_prefix
    if _docker_prefix is None:
        if os.geteuid() == 0:
            _docker_prefix = []
        else:
            works = (
                subprocess.run(["docker", "info"], capture_output=True).returncode == 0
            )
            _docker_prefix = [] if works else ["sudo"]
    return _docker_prefix


def root_prefix():
    return [] if os.geteuid() == 0 else ["sudo"]


def docker(*args, capture=False, check=True):
    return subprocess.run(
        sudo_prefix() + ["docker", *args],
        text=True,
        capture_output=capture,
        check=check,
    )


def docker_cmd():
    """How to run docker by hand, for messages."""
    return " ".join(sudo_prefix() + ["docker"])


def privileged(*args, check=True):
    """Run a file command with the same rights Docker needs (files may be owned
    by the server's user)."""
    return subprocess.run(sudo_prefix() + list(args), check=check)


def write_file(path, content, as_root=False):
    """Write a file, falling back to sudo when the folder isn't ours."""
    if not as_root:
        try:
            Path(path).write_text(content)
            return
        except OSError:
            pass
    prefix = root_prefix() if as_root else sudo_prefix()
    subprocess.run(
        prefix + ["tee", str(path)],
        input=content,
        text=True,
        stdout=subprocess.DEVNULL,
        check=True,
    )


# ════════════════════════════════════════════════════════════════════════
# Containers
# ════════════════════════════════════════════════════════════════════════


def container_exists(name):
    out = docker(
        "ps",
        "-a",
        "--filter",
        f"name=^/{name}$",
        "--format",
        "{{.Names}}",
        capture=True,
    ).stdout
    return name in out.split()


def inspect(name):
    return json.loads(docker("inspect", name, capture=True).stdout)[0]


def image_repo(image):
    """'itzg/minecraft-server:java17' -> 'itzg/minecraft-server'"""
    last = image.rsplit("/", 1)[-1]
    return image[: len(image) - len(last)] + last.split(":", 1)[0].split("@", 1)[0]


def is_world_container(info):
    role = (info["Config"].get("Labels") or {}).get(LABEL)
    if role:
        return role == "world"
    return image_repo(info["Config"]["Image"]) == "itzg/minecraft-server"  # pre-label


def all_worlds():
    """Container info for every hosted world, running or not."""
    names = docker("ps", "-a", "--format", "{{.Names}}", capture=True).stdout.split()
    if not names:
        return []
    infos = json.loads(docker("inspect", *names, capture=True).stdout)
    return [i for i in infos if is_world_container(i)]


def world_settings(info):
    """The settings a world's container was started with."""
    env = dict(e.split("=", 1) for e in info["Config"]["Env"] if "=" in e)
    s = {k: env[k] for k in MANAGED_KEYS if env.get(k)}
    s["IMAGE"] = info["Config"]["Image"]

    binding = (
        (info["HostConfig"].get("PortBindings") or {}).get(f"{CONTAINER_PORT}/tcp")
        or [{}]
    )[0]
    s["PORT"] = binding.get("HostPort") or str(CONTAINER_PORT)
    s["HOST_IP"] = binding.get("HostIp") or ""

    s["DATA"] = next(
        (
            m["Source"]
            for m in info.get("Mounts", [])
            if m.get("Destination") == "/data"
        ),
        None,
    )

    mode = info["HostConfig"].get("NetworkMode") or ""
    s["NETWORK"] = "" if mode in ("", "default", "bridge") else mode
    networks = (info.get("NetworkSettings") or {}).get("Networks") or {}
    s["IP"] = ((networks.get(s["NETWORK"]) or {}).get("IPAMConfig") or {}).get(
        "IPv4Address"
    ) or ""
    return s


def host_addr(ip):
    """IPv6 addresses go in brackets next to a port: '::' -> '[::]'."""
    return f"[{ip}]" if ip and ":" in ip else ip


def start_container(name, s):
    port = f"{s['PORT']}:{CONTAINER_PORT}"
    if s.get("HOST_IP"):
        port = f"{host_addr(s['HOST_IP'])}:{port}"
    args = [
        "run",
        "-d",
        "--name",
        name,
        "--restart",
        "unless-stopped",
        "--label",
        f"{LABEL}=world",
        "-p",
        port,
        "-v",
        f"{s['DATA']}:/data",
        "-e",
        "EULA=TRUE",
    ]
    if s.get("NETWORK"):
        if s["NETWORK"] == NETWORK:
            ensure_network()
        args += ["--network", s["NETWORK"]]
        if s.get("IP"):
            args += ["--ip", s["IP"]]
    for key in MANAGED_KEYS:
        if s.get(key):
            args += ["-e", f"{key}={s[key]}"]
    docker(*args, s.get("IMAGE") or IMAGE)


def stop_and_remove(name):
    docker("stop", "-t", STOP_TIMEOUT, name)
    docker("rm", name)


def recreate(name, old, new):
    """Swap a world's container for one with new settings; roll back on failure."""
    print("Stopping the server (this saves the world)...")
    stop_and_remove(name)
    try:
        start_container(name, new)
    except subprocess.CalledProcessError:
        print(
            "Starting with the new settings failed; restoring the previous ones...",
            file=sys.stderr,
        )
        docker("rm", "-f", name, capture=True, check=False)
        start_container(name, old)
        die("the server is back on its old settings. See the Docker error above.")


def require_world(name):
    if not container_exists(name):
        die(f"no world called '{name}' is hosted. Run './mc.py list' to see them.")
    info = inspect(name)
    if not is_world_container(info):
        die(f"'{name}' is not a world managed by mc.py.")
    return info


def require_running(name):
    if not require_world(name)["State"]["Running"]:
        die(f"'{name}' is not running. Start it with: ./mc.py start {name}")


def require_world_folder(name, s):
    if not s["DATA"]:
        die(
            f"could not find the world folder of '{name}', so it is not safe to recreate it."
        )


def rcon(name, *words, quiet=False):
    """Send one command to the server console."""
    out = docker("exec", name, "rcon-cli", *words, capture=True).stdout.strip()
    if out and not quiet:
        print(out)


# ════════════════════════════════════════════════════════════════════════
# Network and addresses
#   PORT/HOST_IP: the port on this computer and the address it listens on.
#   NETWORK/IP:   the world's fixed address on the isolated Docker network.
# ════════════════════════════════════════════════════════════════════════


def network_subnet():
    """Subnet of the network, or None if it doesn't exist yet. Stops if the
    existing network doesn't match mc.env."""
    r = docker("network", "inspect", NETWORK, capture=True, check=False)
    if r.returncode != 0:
        return None
    info = json.loads(r.stdout)[0]
    config = (info.get("IPAM") or {}).get("Config") or []
    subnet = config[0].get("Subnet") if config else None
    bridge = (info.get("Options") or {}).get("com.docker.network.bridge.name", "")

    problems = []
    if subnet != NETWORK_SUBNET:
        problems.append(f"subnet is {subnet}, settings say {NETWORK_SUBNET}")
    if bridge != NETWORK_BRIDGE:
        problems.append(
            f"bridge is '{bridge or 'automatic'}', settings say '{NETWORK_BRIDGE}'"
        )
    if problems:
        die(
            f"the existing Docker network '{NETWORK}' doesn't match {CONFIG_FILE.name}: "
            f"{'; '.join(problems)}.\nEither change {CONFIG_FILE.name} back, or recreate the "
            f"network: stop the worlds on it, run "
            f"'{docker_cmd()} network rm {NETWORK}', then host them again "
            f"(and update the firewall rules for the new bridge, see the README)."
        )
    return subnet


def ensure_network():
    if network_subnet():
        return
    print(
        f"Creating the Docker network '{NETWORK}' ({NETWORK_SUBNET}, bridge '{NETWORK_BRIDGE}')..."
    )
    docker(
        "network",
        "create",
        "--subnet",
        NETWORK_SUBNET,
        "--opt",
        f"com.docker.network.bridge.name={NETWORK_BRIDGE}",
        NETWORK,
    )


def check_ip(ip):
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        die(f"'{ip}' is not a valid IP address.")
    net = ipaddress.ip_network(network_subnet() or NETWORK_SUBNET)
    if addr not in net:
        die(
            f"{ip} is outside the {NETWORK} network ({net}, set in {CONFIG_FILE.name}). "
            f"Pick something like {EXAMPLE_IP}."
        )
    if addr in (net.network_address, net.network_address + 1, net.broadcast_address):
        die(
            f"{ip} is reserved (network, gateway or broadcast address). Pick another one."
        )


def apply_address_options(s, port=None, ip=None, bind=None):
    """Apply --port/--ip/--bind to settings s (None = unchanged)."""
    if port is not None:
        if not 1 <= port <= 65535:
            die(f"port {port} is out of range (1-65535).")
        s["PORT"] = str(port)
    if bind is not None:
        if bind.lower() in ("all", "none", "", "0.0.0.0"):
            s["HOST_IP"] = ""
        else:
            try:
                ipaddress.ip_address(bind)
            except ValueError:
                die(
                    f"'{bind}' is not a valid address for --bind (e.g. 127.0.0.1, or 'all')."
                )
            s["HOST_IP"] = bind
    if ip is not None:
        if ip.lower() in ("none", ""):
            s["NETWORK"], s["IP"] = "", ""
        else:
            check_ip(ip)
            s["NETWORK"], s["IP"] = NETWORK, ip


def binds_overlap(a, b):
    """'' means all addresses, which overlaps with everything."""
    return not a or not b or a == b


def other_worlds(name):
    return [
        (i["Name"].lstrip("/"), world_settings(i))
        for i in all_worlds()
        if i["Name"].lstrip("/") != name
    ]


def check_conflicts(name, s):
    """Refuse a port or address another world already uses."""
    for other, o in other_worlds(name):
        if o["PORT"] == s["PORT"] and binds_overlap(s.get("HOST_IP"), o.get("HOST_IP")):
            hint = ""
            if s.get("IP"):
                hint = (
                    f"\n--port is the port on this computer, not on {NETWORK}. On "
                    f"{NETWORK} the world always uses {s['IP']}:{CONTAINER_PORT}, "
                    f"so you can leave --port out."
                )
            die(f"{describe_bind(o)} is already used by '{other}'.{hint}")
        if s.get("IP") and o["IP"] == s["IP"] and o["NETWORK"] == s.get("NETWORK"):
            die(f"address {s['IP']} is already used by '{other}'.")


def pick_free_port(name, s):
    taken = [(o["PORT"], o.get("HOST_IP", "")) for _, o in other_worlds(name)]
    for port in range(CONTAINER_PORT, CONTAINER_PORT + 200):
        if not any(
            p == str(port) and binds_overlap(s.get("HOST_IP"), b) for p, b in taken
        ):
            s["PORT"] = str(port)
            return
    die("no free port found between 25565 and 25764. Pick one with --port.")


def describe_bind(s):
    return f"{host_addr(s.get('HOST_IP')) or 'all addresses'}:{s['PORT']}"


def describe_address(s):
    """(host port, network address) for display."""
    port = f"{host_addr(s['HOST_IP'])}:{s['PORT']}" if s.get("HOST_IP") else s["PORT"]
    ip = f"{s['IP']}:{CONTAINER_PORT}" if s.get("IP") else "-"
    return port, ip


# ════════════════════════════════════════════════════════════════════════
# World folders
# ════════════════════════════════════════════════════════════════════════


def level_name(server_dir):
    """The world folder's name from server.properties (default 'world')."""
    props = Path(server_dir) / "server.properties"
    if props.is_file():
        for line in props.read_text(errors="replace").splitlines():
            if line.startswith("level-name="):
                return line.split("=", 1)[1].strip() or "world"
    return "world"


def has_world(server_dir):
    return (Path(server_dir) / level_name(server_dir) / "level.dat").is_file()


def looks_modded(server_dir):
    mods = Path(server_dir) / "mods"
    return mods.is_dir() and any(p.suffix == ".jar" for p in mods.iterdir())


def read_world_version(server_dir):
    """The Minecraft version in level.dat (gzipped NBT: Data > Version > Name), or None."""
    try:
        with gzip.open(
            Path(server_dir) / level_name(server_dir) / "level.dat", "rb"
        ) as f:
            data = f.read()
    except OSError:
        return None
    pos = 0

    def take(fmt):
        nonlocal pos
        value = struct.unpack_from(fmt, data, pos)[0]
        pos += struct.calcsize(fmt)
        return value

    def string():
        nonlocal pos
        n = take(">H")
        pos += n
        return data[pos - n : pos].decode("utf-8", "replace")

    def payload(tag):
        nonlocal pos
        numbers = {1: ">b", 2: ">h", 3: ">i", 4: ">q", 5: ">f", 6: ">d"}
        arrays = {7: 1, 11: 4, 12: 8}
        if tag in numbers:
            return take(numbers[tag])
        if tag in arrays:
            length = take(">i")
            pos += length * arrays[tag]
            return None
        if tag == 8:
            return string()
        if tag == 9:
            item = take(">b")
            count = take(">i")
            return [payload(item) for _ in range(max(count, 0))]
        if tag == 10:
            compound = {}
            while True:
                t = take(">b")
                if t == 0:
                    return compound
                key = string()
                compound[key] = payload(t)
        raise ValueError(f"unknown NBT tag {tag}")

    try:
        if take(">b") != 10:
            return None
        string()
        name = payload(10).get("Data", {}).get("Version", {}).get("Name")
        return name if isinstance(name, str) and name else None
    except (struct.error, ValueError, AttributeError, RecursionError):
        return None


def read_marker(server_dir):
    try:
        return json.loads((Path(server_dir) / MARKER).read_text())
    except (OSError, ValueError):
        return {}


def write_marker(server_dir, s):
    marker = {"type": s.get("TYPE", "PAPER"), "image": s.get("IMAGE") or IMAGE}
    write_file(Path(server_dir) / MARKER, json.dumps(marker, indent=2) + "\n")


def find_minecraft_data(root):
    """('server', dir), ('world', dir) for a lone world folder, or (None, None).
    Looks one folder deeper too, since backups unpack into ./NAME/."""
    root = Path(root)
    candidates = [root]
    subdirs = [p for p in root.iterdir() if p.is_dir()]
    if len(subdirs) == 1 and not (root / "level.dat").exists():
        candidates.append(subdirs[0])
    for d in candidates:
        if (d / "level.dat").is_file():
            return "world", d
        if has_world(d):
            return "server", d
    return None, None


def import_data(source, dest):
    """Copy a server folder, world folder or .tar.gz backup into dest (which
    must be empty). A lone world becomes dest/world."""
    src = Path(source).expanduser().resolve()
    dest = Path(dest)
    if not src.exists():
        die(f"'{source}' does not exist.")
    if dest.exists() and any(dest.iterdir()):
        die(
            f"{dest} already has data in it. Move it somewhere else first (nothing was changed)."
        )

    staging = None
    try:
        if src.is_file():
            if not tarfile.is_tarfile(src):
                die(f"'{source}' is not a folder or a .tar.gz backup.")
            dest.parent.mkdir(parents=True, exist_ok=True)
            staging = Path(tempfile.mkdtemp(prefix=".mc-import-", dir=dest.parent))
            print(f"Unpacking {src.name} ...")
            privileged("tar", "-xzf", str(src), "-C", str(staging))
            look_in = staging
        else:
            look_in = src

        kind, found = find_minecraft_data(look_in)
        if not kind:
            die(
                f"'{source}' doesn't look like Minecraft data: no level.dat found "
                f"(expected a server folder, a world folder or a backup made by mc.py)."
            )

        privileged("mkdir", "-p", str(dest))
        if kind == "server":
            print(f"Importing server folder {found} -> {dest}")
            privileged("cp", "-a", f"{found}/.", str(dest))
        else:
            print(f"Importing world folder {found} -> {dest}/world")
            privileged("cp", "-a", str(found), str(dest / "world"))
        return kind
    finally:
        if staging:
            privileged("rm", "-rf", str(staging), check=False)


def check_name(name, can_use_name_flag=True):
    if not NAME_RE.fullmatch(name):
        hint = " Choose another one with --name." if can_use_name_flag else ""
        die(
            f"'{name}' can't be used as a world name (letters, digits, '.', '_' and '-' "
            f"only, no spaces).{hint}"
        )


def name_from_path(path):
    """castle -> castle, ~/worlds/castle -> castle, base-20261020-040000.tar.gz -> base"""
    name = path.name
    for ext in (".tar.gz", ".tgz", ".tar"):
        if name.endswith(ext):
            return BACKUP_NAME_SUFFIX_RE.sub("", name[: -len(ext)])
    return name


def resolve_existing(arg):
    """A path as given, or a plain name meaning DATA_ROOT/name."""
    path = Path(arg).expanduser()
    if path.exists():
        return path.resolve()
    if "/" not in arg and (DATA_ROOT / arg).exists():
        return (DATA_ROOT / arg).resolve()
    if "/" in arg:
        die(f"'{arg}' not found.")
    die(f"'{arg}' not found (looked for {path.resolve()} and {DATA_ROOT / arg}).")


def resolve_new(arg):
    """Where a new world goes: a path as given, or a plain name under DATA_ROOT."""
    path = Path(arg).expanduser()
    if "/" not in arg and not path.is_absolute():
        path = DATA_ROOT / arg
    return path.resolve()


# ════════════════════════════════════════════════════════════════════════
# Versions and server types
# ════════════════════════════════════════════════════════════════════════


def normalize_version(v):
    if v is None or v.strip().lower() in ("", "latest"):
        return "LATEST"
    return v.strip()


def version_tuple(v):
    m = re.fullmatch(r"(\d+)\.(\d+)(?:\.(\d+))?", v or "")
    return tuple(int(x or 0) for x in m.groups()) if m else None


def normalize_type(t):
    t = (t or "").strip().upper()
    if not re.fullmatch(r"[A-Z_]+", t):
        die(
            f"'{t}' is not a server type. Examples: PAPER, VANILLA, PURPUR, {MODDED_EXAMPLES}."
        )
    return t


def java_hint(version, image):
    """Old Minecraft needs an older Java than the image's default."""
    v = version_tuple(version)
    if not v or ":" in image.rsplit("/", 1)[-1] or v >= (1, 20, 5):
        return
    tag = "java8" if v < (1, 17) else "java17"
    print(
        f"Note: Minecraft {version} needs an older Java than the default image has. "
        f"If the server fails to start, host it again with:\n"
        f"  --replace --image {image_repo(image)}:{tag}"
    )


def image_for_version(image, version):
    """Switch an old-Java image (e.g. :java17) back to the normal one when the
    version needs a newer Java."""
    tag = image.rsplit("/", 1)[-1].partition(":")[2]
    v = version_tuple(version)
    if tag in OLD_JAVA_TAGS and (version == "LATEST" or (v and v >= (1, 20, 5))):
        return image_repo(image)
    return image


# ════════════════════════════════════════════════════════════════════════
# Backups
# ════════════════════════════════════════════════════════════════════════


def archive_folder(name, server_dir, suffix=""):
    """Write BACKUP_DIR/NAME-DATE-TIME[suffix].tar.gz. A .partial file is used
    until it's complete, so an interrupted backup never looks finished."""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    dest = BACKUP_DIR / f"{name}-{stamp}{suffix}.tar.gz"
    partial = dest.with_name(dest.name + ".partial")
    src = Path(server_dir)
    excludes = [f"--exclude=./{src.name}/{e}" for e in BACKUP_EXCLUDES]
    print(f"Backing up {src} -> {dest} ...")
    try:
        privileged(
            "tar",
            "-czf",
            str(partial),
            *excludes,
            "-C",
            str(src.parent),
            f"./{src.name}",
        )
        privileged("mv", str(partial), str(dest))
    finally:
        if partial.exists():
            privileged("rm", "-f", str(partial), check=False)
    return dest


def prune_backups(name, keep):
    """Keep the newest `keep` nightly backups of a world (0 = all).
    Pre-upgrade backups are never deleted."""
    if keep <= 0 or not BACKUP_DIR.exists():
        return
    pattern = re.compile(rf"{re.escape(name)}-\d{{8}}-\d{{6}}\.tar\.gz")
    nightly = sorted(p for p in BACKUP_DIR.iterdir() if pattern.fullmatch(p.name))
    for old in nightly[:-keep]:
        print(f"  removing old backup {old.name}")
        privileged("rm", "-f", str(old))


def backup_world(info, keep):
    """Back up one world without stopping it. Returns True on success."""
    name = info["Name"].lstrip("/")
    s = world_settings(info)
    if not s["DATA"]:
        print(f"[{name}] no world folder found, skipping.", file=sys.stderr)
        return False
    running = info["State"]["Running"]
    print(f"[{name}] {'running: pausing world saves' if running else 'stopped'}")
    try:
        if running:
            rcon(name, "save-off", quiet=True)
            rcon(name, "save-all", "flush", quiet=True)
        dest = archive_folder(name, s["DATA"])
    except subprocess.CalledProcessError as e:
        print(f"[{name}] backup FAILED: {' '.join(e.cmd)}", file=sys.stderr)
        return False
    finally:
        if (
            running
            and docker(
                "exec", name, "rcon-cli", "save-on", capture=True, check=False
            ).returncode
            != 0
        ):
            print(
                f"[{name}] WARNING: could not turn saving back on. Run: "
                f"./mc.py cmd {name} save-on",
                file=sys.stderr,
            )
    print(f"[{name}] saved {dest.name} ({dest.stat().st_size / 1_048_576:.1f} MB)")
    prune_backups(name, keep)
    return True


# ════════════════════════════════════════════════════════════════════════
# Output
# ════════════════════════════════════════════════════════════════════════


def print_world(name, s, heading):
    port, ip = describe_address(s)
    whitelist = {"TRUE": "on", "FALSE": "OFF"}.get(
        s.get("ENABLE_WHITELIST", ""), "as in server.properties"
    )
    print(f"{heading} '{name}'...")
    print(f"  Type:        {s.get('TYPE', 'PAPER')}")
    print(f"  Image:       {s.get('IMAGE') or IMAGE}")
    print(f"  Version:     {s['VERSION']}")
    print(f"  Online mode: {s['ONLINE_MODE']}")
    print(f"  Whitelist:   {whitelist}")
    print(f"  Memory:      {s['MEMORY']}")
    print(f"  Game mode:   {s.get('MODE') or 'as in server.properties'}")
    print(f"  Port:        {port}")
    print(f"  Address:     {ip if s.get('IP') else '(not on ' + NETWORK + ')'}")
    print(f"  World data:  {s['DATA']}")


def print_next_steps(name, s):
    port, ip = describe_address(s)
    print(f"\n'{name}' is starting (port {port}).")
    bind = s.get("HOST_IP") or ""
    if bind == "::" or not bind:
        print(
            f"Players connect to [YOUR_IPV6]:{s['PORT']} (see: ip -6 addr show scope global;"
            f" use the 'mngtmpaddr' one). Port {s['PORT']} must be in publicPorts"
            f" (settings.nix) and open in the router's IPv6 firewall."
        )
    elif bind in ("127.0.0.1", "::1"):
        print(f"Only reachable from this machine ({host_addr(bind)}:{s['PORT']}).")
    print("\nNext:")
    if s.get("ENABLE_WHITELIST") == "TRUE":
        print(
            f"  ./mc.py whitelist {name} add YourName     (nobody can join until listed)"
        )
    print(f"  ./mc.py logs {name} -f                    (watch it start)")


# ════════════════════════════════════════════════════════════════════════
# Commands: worlds
# ════════════════════════════════════════════════════════════════════════


def cmd_create(a):
    """Generate a new world with a temporary server, then stop."""
    data = resolve_new(a.path)
    name = data.name
    check_name(name, can_use_name_flag=False)
    if data.exists() and any(data.iterdir()):
        hint = (
            f"It already contains a world; run it with: ./mc.py host {a.path}"
            if has_world(data)
            else "Pick another folder or move it away first."
        )
        die(f"{data} is not empty, so 'create' won't touch it. {hint}")

    image = a.image or IMAGE
    env = {
        "TYPE": normalize_type(a.type or "PAPER"),
        "VERSION": normalize_version(a.version),
        "MEMORY": DEFAULT_MEMORY,
        "SEED": a.seed or "",
        "LEVEL_TYPE": "minecraft:flat" if a.flat else "",
        "MODE": a.mode or "",
        "FORCE_GAMEMODE": "true" if a.mode else "",
    }
    print(f"Creating a new world in {data}")
    print(
        f"  Type:       {env['TYPE']}" + (f" (image {image})" if image != IMAGE else "")
    )
    print(f"  Version:    {env['VERSION']}")
    print(f"  World type: {'flat' if a.flat else 'normal'}")
    if a.seed:
        print(f"  Seed:       {a.seed}")
    if a.mode:
        print(f"  Game mode:  {a.mode}")
    print(
        "Generating (a temporary server runs until the world is ready; the first "
        "time can take a few minutes)",
        end="",
        flush=True,
    )

    tmp = f"mc-create-{name}"
    docker("rm", "-f", tmp, capture=True, check=False)
    data.mkdir(parents=True, exist_ok=True)
    args = [
        "run",
        "-d",
        "--name",
        tmp,
        "--label",
        f"{LABEL}=create",
        "-v",
        f"{data}:/data",
        "-e",
        "EULA=TRUE",
    ]
    args += [x for k, v in env.items() if v for x in ("-e", f"{k}={v}")]
    docker(*args, image, capture=True)

    finished, logs = False, ""
    try:
        deadline = time.monotonic() + CREATE_TIMEOUT
        while time.monotonic() < deadline:
            r = docker("logs", tmp, capture=True, check=False)
            logs = (r.stdout or "") + (r.stderr or "")
            if re.search(r"Done \(\d", logs):
                finished = True
                break
            if not inspect(tmp)["State"]["Running"]:
                break
            print(".", end="", flush=True)
            time.sleep(CREATE_POLL)
    finally:
        print()
        docker("stop", "-t", STOP_TIMEOUT, tmp, capture=True, check=False)
        docker("rm", tmp, capture=True, check=False)

    if not finished or not has_world(data):
        tail = "\n".join(logs.strip().splitlines()[-25:])
        die(
            f"the world could not be created. Last server output:\n{tail}\n"
            f"(The folder {data} was left as-is so you can inspect it.)"
        )

    write_marker(data, {"TYPE": env["TYPE"], "IMAGE": image})
    version = read_world_version(data) or env["VERSION"]
    print(f"World created: {data} (Minecraft {version}, {env['TYPE']})")
    print(
        f"Nothing is running yet. To host it:\n  ./mc.py host {a.path} --ip {EXAMPLE_IP}"
    )


def host_settings(a, old, marker, data):
    """Settings for 'host': given options, then the old container's, then the
    world's marker, then defaults."""
    o = old or {}

    def flag(on, off, previous, default):
        return "TRUE" if on else "FALSE" if off else o.get(previous) or default

    whitelist = flag(
        a.whitelist, a.no_whitelist, "ENABLE_WHITELIST", "" if old else "TRUE"
    )
    return {
        "IMAGE": a.image or o.get("IMAGE") or marker.get("image") or IMAGE,
        "TYPE": (
            normalize_type(a.type)
            if a.type
            else o.get("TYPE")
            or (normalize_type(marker["type"]) if marker.get("type") else "")
        ),
        "VERSION": normalize_version(a.version) if a.version else o.get("VERSION", ""),
        "MEMORY": a.memory or o.get("MEMORY") or DEFAULT_MEMORY,
        "ONLINE_MODE": flag(a.online, a.cracked, "ONLINE_MODE", "TRUE"),
        "ENABLE_WHITELIST": whitelist,
        "ENFORCE_WHITELIST": whitelist,
        "MODE": a.mode or o.get("MODE", ""),
        "FORCE_GAMEMODE": "true" if a.mode else o.get("FORCE_GAMEMODE", ""),
        "PORT": o.get("PORT", str(CONTAINER_PORT)),
        "HOST_IP": o.get("HOST_IP", "") if old else DEFAULT_BIND,
        "NETWORK": o.get("NETWORK", ""),
        "IP": o.get("IP", ""),
        "DATA": str(data),
    }


def cmd_host(a):
    """Run a world that already exists. Never generates a new one."""
    src = resolve_existing(a.path)
    name = a.name or name_from_path(src)
    check_name(name, can_use_name_flag=not a.name)

    old = world_settings(inspect(name)) if container_exists(name) else None
    if old and not a.replace:
        die(
            f"'{name}' is already hosted (world: {old['DATA']}). Add --replace to recreate "
            f"it with new options (the world is kept), or use --name for a different name."
        )

    # Where the world will live: server folders are hosted in place, lone
    # worlds and backups are copied into DATA_ROOT/NAME.
    if src.is_file():
        kind = "backup"
    else:
        kind, found = find_minecraft_data(src)
        if not kind:
            die(
                f"no world found in {src} (no level.dat). To make a new world use: "
                f"./mc.py create {a.path}"
            )
    if kind == "server":
        data = found
    else:
        data = (DATA_ROOT / name).resolve()
        if kind == "world" and found.resolve() == data:
            die(
                f"{data} is a single world folder, not a server folder. Move it somewhere "
                f"else (e.g. ~/saves/{name}) and run: ./mc.py host <that folder>"
            )

    if old and old["DATA"] and Path(old["DATA"]).resolve() != data:
        die(
            f"'{name}' already hosts a different world ({old['DATA']}). "
            f"Use --name to host this one under another name."
        )
    for other, o in other_worlds(name):
        if o["DATA"] and Path(o["DATA"]).resolve() == data:
            die(
                f"that world is already hosted as '{other}'. Two servers can't share a world."
            )

    s = host_settings(a, old, read_marker(data), data)
    if not s["TYPE"] and kind == "server" and looks_modded(data):
        die(
            f"{data} has a mods folder, so it's a modded server. Say which kind with "
            f"--type ({MODDED_EXAMPLES}). Running it as Paper would permanently delete "
            f"its modded blocks and items."
        )

    apply_address_options(s, a.port, a.ip, a.bind)
    if a.port is None and not old:
        pick_free_port(name, s)
    check_conflicts(name, s)

    if kind != "server":
        print(f"Imported {import_data(src, data)} into {data}")
        if not s["TYPE"]:
            marker = read_marker(data)
            if marker.get("type"):
                s["TYPE"] = normalize_type(marker["type"])
                s["IMAGE"] = a.image or marker.get("image") or s["IMAGE"]
            elif looks_modded(data):
                die(
                    f"the imported server has a mods folder, so it's modded. Nothing is "
                    f"running. Host the imported copy with its type, e.g.:\n"
                    f"  ./mc.py host {data} --type FABRIC   ({MODDED_EXAMPLES})"
                )
    s["TYPE"] = s["TYPE"] or "PAPER"

    if not s["VERSION"]:
        detected = read_world_version(data)
        if detected:
            s["VERSION"] = detected
            print(
                f"World was last played on Minecraft {detected}: hosting it on that "
                f"version (upgrade later with ./mc.py upgrade {name})."
            )
        else:
            s["VERSION"] = "LATEST"
            print(
                "Couldn't read the world's version, so using the newest Minecraft. If the "
                "world is older, it will be upgraded permanently; stop now and pass "
                "--version X.Y.Z to avoid that."
            )
    java_hint(s["VERSION"], s["IMAGE"])

    if old:
        print(
            f"Removing the old container of '{name}' (the world in {data} is kept)..."
        )
        stop_and_remove(name)
    write_marker(data, s)
    print_world(name, s, "Hosting")
    start_container(name, s)
    print_next_steps(name, s)


def cmd_unhost(a):
    s = world_settings(require_world(a.name))
    print(f"Stopping '{a.name}' (this saves the world)...")
    stop_and_remove(a.name)
    print(f"'{a.name}' is no longer hosted. Its world is still in {s['DATA']}.")
    again = f"./mc.py host {s['DATA']}" + (f" --ip {s['IP']}" if s.get("IP") else "")
    print(f"Host it again with: {again}")


def cmd_rename(a):
    """Rename a world: its container, its folder (when named after it) and its backups."""
    old_name, new_name = a.name, a.new_name
    s = world_settings(require_world(old_name))
    require_world_folder(old_name, s)
    check_name(new_name, can_use_name_flag=False)
    if container_exists(new_name):
        die(f"there is already a world (or container) called '{new_name}'.")

    old_data = Path(s["DATA"])
    move_folder = not a.keep_folder and old_data.name == old_name
    new_data = old_data.with_name(new_name) if move_folder else old_data
    if move_folder and new_data.exists():
        die(f"{new_data} already exists. Move it away first, or use --keep-folder.")

    print(f"Renaming '{old_name}' to '{new_name}'...")
    print("Stopping the server (this saves the world)...")
    stop_and_remove(old_name)

    if (
        move_folder
        and privileged("mv", str(old_data), str(new_data), check=False).returncode != 0
    ):
        start_container(old_name, s)
        die(
            f"couldn't rename {old_data}, so nothing was changed (the server was restarted)."
        )
    new = dict(s, DATA=str(new_data))
    try:
        start_container(new_name, new)
    except subprocess.CalledProcessError:
        print(
            "Starting under the new name failed; undoing the rename...", file=sys.stderr
        )
        docker("rm", "-f", new_name, capture=True, check=False)
        if move_folder:
            privileged("mv", str(new_data), str(old_data), check=False)
        start_container(old_name, s)
        die(f"'{old_name}' is back as it was. See the Docker error above.")

    renamed = 0
    if BACKUP_DIR.is_dir():
        pattern = re.compile(
            rf"{re.escape(old_name)}(-\d{{8}}-\d{{6}}(?:-pre-upgrade)?\.tar\.gz)"
        )
        for backup in sorted(BACKUP_DIR.iterdir()):
            m = pattern.fullmatch(backup.name)
            target = BACKUP_DIR / (new_name + m.group(1)) if m else None
            if target and not target.exists():
                privileged("mv", str(backup), str(target))
                renamed += 1

    print(f"Done. '{old_name}' is now '{new_name}'.")
    if move_folder:
        print(f"  Folder:  {old_data} -> {new_data}")
    else:
        print(f"  Folder:  unchanged ({old_data})")
    print(f"  Backups: {renamed} renamed to {new_name}-…")
    print(f"  Port:    unchanged ({describe_address(s)[0]})")


def cmd_start(a):
    require_world(a.name)
    docker("start", a.name, capture=True)
    print(f"'{a.name}' is starting. Watch it with: ./mc.py logs {a.name} -f")


def cmd_stop(a):
    require_world(a.name)
    print(f"Stopping '{a.name}' (this saves the world)...")
    docker("stop", "-t", STOP_TIMEOUT, a.name, capture=True)
    print(f"Stopped. It stays stopped until: ./mc.py start {a.name}")


def cmd_restart(a):
    require_world(a.name)
    print(f"Restarting '{a.name}' (this saves the world)...")
    docker("restart", "-t", STOP_TIMEOUT, a.name, capture=True)
    print(f"Restarted. Watch it with: ./mc.py logs {a.name} -f")


def cmd_set(a):
    if a.port is None and a.ip is None and a.bind is None:
        die("nothing to change. Use --port, --ip and/or --bind.")
    old = world_settings(require_world(a.name))
    require_world_folder(a.name, old)
    new = dict(old)
    apply_address_options(new, a.port, a.ip, a.bind)
    check_conflicts(a.name, new)

    (old_port, old_ip), (new_port, new_ip) = describe_address(old), describe_address(
        new
    )
    if (old_port, old_ip) == (new_port, new_ip):
        print("Nothing changed.")
        return
    print(f"Changing '{a.name}':")
    print(f"  Port:    {old_port} -> {new_port}")
    print(f"  Address: {old_ip} -> {new_ip}")
    recreate(a.name, old, new)
    print_next_steps(a.name, new)
    print(
        "\nIf the port changed: update publicPorts in settings.nix, rebuild, and update the router."
    )


def cmd_upgrade(a):
    s = world_settings(require_world(a.name))
    require_world_folder(a.name, s)
    old_version, new_version = s.get("VERSION", "LATEST"), normalize_version(a.version)
    print(f"Upgrading '{a.name}': {old_version} -> {new_version}")
    print("Note: Minecraft worlds can't be downgraded safely; only move forward.\n")

    image = image_for_version(s["IMAGE"], new_version)
    if image != s["IMAGE"]:
        print(
            f"Minecraft {new_version} needs a newer Java than {s['IMAGE']}, "
            f"so switching to {image}.\n"
        )
        s["IMAGE"] = image

    print("Pulling the newest server image...")
    docker("pull", s["IMAGE"])
    print("Stopping the server (this saves the world)...")
    docker("stop", "-t", STOP_TIMEOUT, a.name)
    if not a.no_backup:
        try:
            print(f"Backup saved: {archive_folder(a.name, s['DATA'], '-pre-upgrade')}")
        except subprocess.CalledProcessError:
            docker("start", a.name)
            die(
                "the backup failed, so nothing was upgraded (the server was restarted)."
            )

    docker("rm", a.name)
    s["VERSION"] = new_version
    write_marker(s["DATA"], s)
    start_container(a.name, s)
    print_next_steps(a.name, s)


def cmd_restore(a):
    """Replace a hosted world with a backup, keeping its settings and address."""
    s = world_settings(require_world(a.name))
    require_world_folder(a.name, s)
    backup = Path(a.backup).expanduser().resolve()
    if not backup.is_file() or not tarfile.is_tarfile(backup):
        die(f"'{a.backup}' is not a backup file (.tar.gz).")

    data = Path(s["DATA"])
    aside = data.with_name(f"{data.name}.before-restore-{datetime.now():%Y%m%d-%H%M%S}")
    print(f"Restoring '{a.name}' from {backup.name}")
    print("Stopping the server (this saves the world)...")
    stop_and_remove(a.name)
    if privileged("mv", str(data), str(aside), check=False).returncode != 0:
        start_container(a.name, s)
        die(
            f"couldn't move {data} aside, so nothing was restored (the server was restarted)."
        )
    try:
        import_data(backup, data)
    except (SystemExit, subprocess.CalledProcessError):
        print("Restore failed: putting the previous world back...", file=sys.stderr)
        privileged("rm", "-rf", str(data), check=False)
        privileged("mv", str(aside), str(data))
        start_container(a.name, s)
        raise

    s["IMAGE"] = image_for_version(s["IMAGE"], s.get("VERSION", "LATEST"))
    start_container(a.name, s)
    print(f"\nRestored. The world as it was before is kept in:\n  {aside}")
    print("Delete it once you're happy with the restored world.")
    print_next_steps(a.name, s)


# ════════════════════════════════════════════════════════════════════════
# Commands: players and console
# ════════════════════════════════════════════════════════════════════════


def cmd_whitelist(a):
    require_running(a.name)
    if a.action == "list":
        rcon(a.name, "whitelist", "list")
        return
    if not a.players:
        die(
            f"give at least one player name, e.g. ./mc.py whitelist {a.name} {a.action} Steve"
        )
    for player in a.players:
        rcon(a.name, "whitelist", a.action, player)


def cmd_op(a):
    require_running(a.name)
    if a.action == "list":
        raw = docker("exec", a.name, "cat", "/data/ops.json", capture=True).stdout
        ops = [o.get("name", "?") for o in json.loads(raw or "[]")]
        print("Operators: " + (", ".join(ops) if ops else "(none)"))
        return
    if not a.players:
        die(f"give at least one player name, e.g. ./mc.py op {a.name} {a.action} Steve")
    for player in a.players:
        rcon(a.name, "op" if a.action == "add" else "deop", player)


def cmd_console(a):
    require_running(a.name)
    print(
        "Type server commands without a slash. Ctrl+C or Ctrl+D to leave "
        "(the server keeps running)."
    )
    subprocess.run(sudo_prefix() + ["docker", "exec", "-it", a.name, "rcon-cli"])


def cmd_cmd(a):
    require_running(a.name)
    rcon(a.name, *a.words)


def cmd_logs(a):
    require_world(a.name)
    args = ["docker", "logs", "--tail", str(a.lines)] + (["-f"] if a.follow else [])
    try:
        subprocess.run(sudo_prefix() + args + [a.name])
    except KeyboardInterrupt:
        pass


# ════════════════════════════════════════════════════════════════════════
# Commands: backups
# ════════════════════════════════════════════════════════════════════════


def cmd_backup(a):
    if a.all == bool(a.name):
        die("give a world name, or --all for every world.")
    infos = all_worlds() if a.all else [require_world(a.name)]
    if not infos:
        print("No worlds are hosted.")
        return
    results = [backup_world(info, a.keep) for info in infos]
    print(f"\nBackups in {BACKUP_DIR}")
    if not all(results):
        die(f"{results.count(False)} backup(s) failed.")


def cmd_schedule_backups(a):
    service = SYSTEMD_DIR / f"{BACKUP_UNIT}.service"
    timer = SYSTEMD_DIR / f"{BACKUP_UNIT}.timer"
    if not SYSTEMD_RUNNING or not shutil.which("systemctl"):
        hour, minute = (a.time or BACKUP_TIME).split(":")
        die(
            "this system isn't running systemd, so schedule the backup with cron "
            "instead (sudo crontab -e):\n"
            f"  {int(minute)} {int(hour)} * * * {sys.executable} {Path(__file__).resolve()} backup --all"
        )

    if a.status:
        if not timer.exists():
            print(
                "Nightly backups are not scheduled. Turn them on with: ./mc.py schedule-backups"
            )
            return
        subprocess.run(
            root_prefix()
            + ["systemctl", "list-timers", f"{BACKUP_UNIT}.timer", "--no-pager"]
        )
        print(f"\nLast runs: journalctl -u {BACKUP_UNIT} --no-pager -n 30")
        return

    if a.off:
        subprocess.run(
            root_prefix() + ["systemctl", "disable", "--now", f"{BACKUP_UNIT}.timer"]
        )
        subprocess.run(
            root_prefix() + ["rm", "-f", str(service), str(timer)], check=True
        )
        subprocess.run(root_prefix() + ["systemctl", "daemon-reload"], check=True)
        print("Nightly backups turned off. Existing backups were not touched.")
        return

    when = a.time or BACKUP_TIME
    if not re.fullmatch(r"([01]\d|2[0-3]):[0-5]\d", when):
        die(
            f"the backup time must look like 04:00 (24-hour clock), not '{when}' "
            f"(--time or MC_BACKUP_TIME)."
        )

    script = Path(__file__).resolve()

    def quote(text):
        return f'"{text}"'

    keep_arg = f" --keep {a.keep}" if a.keep is not None else ""
    env_lines = "".join(
        f"Environment={quote(f'{k}={os.environ[k]}')}\n"
        for k in ("MC_CONFIG", *SETTING_DEFAULTS)
        if os.environ.get(k)
    )
    write_file(
        service,
        f"""\
[Unit]
Description=Nightly backup of all Minecraft worlds (mc.py)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
{env_lines}ExecStart={quote(sys.executable)} {quote(script)} backup --all{keep_arg}
Nice=10
IOSchedulingClass=idle
""",
        as_root=True,
    )
    write_file(
        timer,
        f"""\
[Unit]
Description=Run the Minecraft backup every night at {when}

[Timer]
OnCalendar=*-*-* {when}:00
Persistent=true
RandomizedDelaySec=10m

[Install]
WantedBy=timers.target
""",
        as_root=True,
    )
    subprocess.run(root_prefix() + ["systemctl", "daemon-reload"], check=True)
    subprocess.run(
        root_prefix() + ["systemctl", "enable", "--now", f"{BACKUP_UNIT}.timer"],
        check=True,
    )

    keep = a.keep if a.keep is not None else BACKUP_KEEP
    print(f"Nightly backups scheduled at {when} (keeping {keep} per world).")
    print(f"  Backups go to: {BACKUP_DIR}")
    print(f"  Uses this script: {script}")
    print("  If you move the script or change MC_BACKUP_TIME, run this command again.")
    print("  If the computer is off at that time, the backup runs at the next start.")
    print("  Check:    ./mc.py schedule-backups --status")
    print(f"  Run now:  sudo systemctl start {BACKUP_UNIT}")
    print("  Turn off: ./mc.py schedule-backups --off")


# ════════════════════════════════════════════════════════════════════════
# Commands: overview
# ════════════════════════════════════════════════════════════════════════


def cmd_list(a):
    worlds = all_worlds()
    if not worlds:
        print("No worlds are hosted.")
        return
    width = max(len("NAME"), *(len(i["Name"].lstrip("/")) for i in worlds)) + 2
    print(
        f"{'NAME':<{width}}{'STATUS':<10}{'PORT':<17}{'ADDRESS':<19}"
        f"{'TYPE':<10}{'VERSION':<10}{'ONLINE':<8}WORLD"
    )
    for info in worlds:
        s = world_settings(info)
        port, ip = describe_address(s)
        print(
            f"{info['Name'].lstrip('/'):<{width}}{info['State']['Status']:<10}"
            f"{port:<17}{ip:<19}{s.get('TYPE', '?'):<10}{s.get('VERSION', '?'):<10}"
            f"{s.get('ONLINE_MODE', '?'):<8}{s['DATA']}"
        )


def cmd_config(a):
    source = (
        CONFIG_FILE
        if CONFIG_FILE.is_file()
        else f"{CONFIG_FILE} (missing: using defaults)"
    )
    print(f"Settings from {source}\n")
    for key in SETTING_DEFAULTS:
        note = " (from environment)" if os.environ.get(key) else ""
        print(f"  {key:<20} {SETTINGS[key] or '(default)'}{note}")
    print(f"\n  worlds go to        {DATA_ROOT}")
    print(f"  backups go to       {BACKUP_DIR}")


# ════════════════════════════════════════════════════════════════════════
# Command line
# ════════════════════════════════════════════════════════════════════════


def build_parser():
    p = argparse.ArgumentParser(
        description="Run Minecraft servers in Docker. Settings: mc.env next to this script."
    )
    sub = p.add_subparsers(dest="command", required=True, metavar="COMMAND")

    def command(name, func, help_text, world_name=False):
        sp = sub.add_parser(name, help=help_text, description=help_text)
        sp.set_defaults(func=func)
        if world_name:
            sp.add_argument("name", help="world name (see ./mc.py list)")
        return sp

    type_help = f"server type: PAPER (default), VANILLA, PURPUR, {MODDED_EXAMPLES}, ..."

    # Worlds
    c = command("create", cmd_create, "generate a new world (doesn't host it)")
    c.add_argument("path", help="new folder: a name (= ~/NAME) or a path")
    c.add_argument("--seed", help="world seed")
    c.add_argument("--flat", action="store_true", help="superflat world")
    c.add_argument("--version", help="Minecraft version (default: latest)")
    c.add_argument(
        "--mode", choices=GAME_MODES, help="default game mode (default: survival)"
    )
    c.add_argument("--type", help=type_help)
    c.add_argument("--image", help=f"Docker image (default: {IMAGE})")

    h = command("host", cmd_host, "run an existing world (never generates a new one)")
    h.add_argument(
        "path",
        help="server folder, world folder (e.g. a singleplayer save) or "
        ".tar.gz backup; a plain name means ~/NAME",
    )
    h.add_argument("--name", help="world name (default: the folder name)")
    h.add_argument(
        "--ip", help=f"address on the '{NETWORK}' network, e.g. {EXAMPLE_IP}"
    )
    h.add_argument(
        "--port",
        type=int,
        help="port on this computer (default: first free from 25565)",
    )
    h.add_argument(
        "--bind",
        help=f"address the port listens on: '::' for IPv6 players, 127.0.0.1 for this "
        f"machine only, 'all' for IPv4+IPv6 (default: {DEFAULT_BIND})",
    )
    h.add_argument("--version", help="Minecraft version (default: the world's own)")
    h.add_argument("--memory", help=f"RAM (default: {DEFAULT_MEMORY})")
    h.add_argument("--mode", choices=GAME_MODES, help="force a game mode on everyone")
    h.add_argument("--type", help=type_help + " (required for modded servers)")
    h.add_argument(
        "--image",
        help=f"Docker image (default: {IMAGE}; e.g. {IMAGE}:java8 for old Minecraft)",
    )
    online = h.add_mutually_exclusive_group()
    online.add_argument(
        "--cracked",
        action="store_true",
        help="offline mode (needs a login plugin, see README)",
    )
    online.add_argument(
        "--online", action="store_true", help="online mode (the default)"
    )
    whitelist = h.add_mutually_exclusive_group()
    whitelist.add_argument(
        "--no-whitelist", action="store_true", help="let anyone join (not recommended)"
    )
    whitelist.add_argument(
        "--whitelist",
        action="store_true",
        help="only listed players can join (the default)",
    )
    h.add_argument(
        "--replace",
        action="store_true",
        help="re-host an already hosted world with new options",
    )

    command(
        "unhost",
        cmd_unhost,
        "stop hosting a world (its folder is kept)",
        world_name=True,
    )
    rn = command(
        "rename",
        cmd_rename,
        "rename a world (and its folder and backups)",
        world_name=True,
    )
    rn.add_argument("new_name", help="the new name")
    rn.add_argument(
        "--keep-folder",
        action="store_true",
        help="only rename the world, not its folder",
    )

    command("start", cmd_start, "start a stopped world", world_name=True)
    command("stop", cmd_stop, "stop a world until started again", world_name=True)
    command(
        "restart",
        cmd_restart,
        "restart a world (e.g. after editing server.properties)",
        world_name=True,
    )

    st = command(
        "set", cmd_set, "change a world's port or address only", world_name=True
    )
    st.add_argument(
        "--ip", help=f"new address on '{NETWORK}', or 'none' to leave the network"
    )
    st.add_argument("--port", type=int, help="new port on this computer")
    st.add_argument("--bind", help="address the port listens on: '::', 127.0.0.1 or 'all'")

    u = command(
        "upgrade",
        cmd_upgrade,
        "move a world to a newer Minecraft (backs up first)",
        world_name=True,
    )
    u.add_argument("--version", help="target version (default: latest)")
    u.add_argument("--no-backup", action="store_true", help="skip the backup")

    r = command(
        "restore",
        cmd_restore,
        "replace a world with a backup (keeps its settings)",
        world_name=True,
    )
    r.add_argument("backup", help="a .tar.gz from the backups folder")

    # Players and console
    w = command(
        "whitelist",
        cmd_whitelist,
        "add, remove or list whitelisted players",
        world_name=True,
    )
    w.add_argument("action", choices=["add", "remove", "list"])
    w.add_argument("players", nargs="*", help="player names")

    o = command("op", cmd_op, "add, remove or list operators (admins)", world_name=True)
    o.add_argument("action", choices=["add", "remove", "list"])
    o.add_argument("players", nargs="*", help="player names")

    command("console", cmd_console, "open the server console", world_name=True)

    cm = command(
        "cmd",
        cmd_cmd,
        "run one server command, e.g. cmd base say hello",
        world_name=True,
    )
    cm.add_argument(
        "words", nargs=argparse.REMAINDER, help="the command, without a slash"
    )

    lg = command("logs", cmd_logs, "show a world's server output", world_name=True)
    lg.add_argument(
        "-f", "--follow", action="store_true", help="keep showing new output"
    )
    lg.add_argument(
        "-n", "--lines", type=int, default=100, help="lines to show (default: 100)"
    )

    # Backups
    b = command("backup", cmd_backup, "back up a world (or --all) without stopping it")
    b.add_argument("name", nargs="?", help="world name")
    b.add_argument("--all", action="store_true", help="every world")
    b.add_argument(
        "--keep",
        type=int,
        default=BACKUP_KEEP,
        help=f"nightly backups to keep per world, 0 = all (default: {BACKUP_KEEP})",
    )

    sb = command(
        "schedule-backups", cmd_schedule_backups, "back up every world each night"
    )
    sb.add_argument("--time", help=f"time of day, 24h clock (default: {BACKUP_TIME})")
    sb.add_argument(
        "--keep", type=int, help=f"backups to keep per world (default: {BACKUP_KEEP})"
    )
    sb.add_argument("--off", action="store_true", help="stop the nightly backups")
    sb.add_argument(
        "--status", action="store_true", help="show when the next backup runs"
    )

    # Overview
    command("list", cmd_list, "show hosted worlds")
    command("config", cmd_config, "show the settings in use (from mc.env)")
    return p


def main():
    args = build_parser().parse_args()
    try:
        args.func(args)
    except subprocess.CalledProcessError as e:
        die(f"command failed: {' '.join(map(str, e.cmd))}")
    except FileNotFoundError as e:
        die(
            f"{e.filename or 'a required program'} is not installed or not on the PATH."
        )


if __name__ == "__main__":
    main()
