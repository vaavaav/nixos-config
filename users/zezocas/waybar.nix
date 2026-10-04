{ pkgs, ... }:
let
  dim = text: "<span foreground='#727169'>${text}</span>";

  niri-columns = pkgs.writeShellScript "niri-columns" ''
    niri msg -j event-stream | while read -r _; do
      niri msg -j windows | ${pkgs.jq}/bin/jq -c '
        (map(select(.is_focused))[0]) as $f
        | ($f.layout.pos_in_scrolling_layout[0] // 0) as $cur
        | ([.[] | select(.workspace_id == $f.workspace_id) | .layout.pos_in_scrolling_layout[0] // empty] | max // 0) as $n
        | if $n < 2 then {text: ""}
          else {text: [range(1; $n + 1) | if . == $cur then "●" else "○" end] | join(" "), tooltip: "Column \($cur) of \($n)"}
          end'
    done
  '';
in
{
  programs.waybar = {
    enable = true;

    settings.mainBar = {
      layer = "top";
      height = 34;
      margin-top = 3;
      margin-left = 9;
      margin-right = 9;
      spacing = 8;

      modules-left = [ "niri/workspaces" "custom/columns" "mpris" ];
      modules-center = [ "clock" ];
      modules-right = [ "network" "pulseaudio" "cpu" "memory" "disk" "battery" ];

      "niri/workspaces".format = "{index}";

      "custom/columns" = {
        exec = "${niri-columns}";
        return-type = "json";
        restart-interval = 2;
      };

      mpris = {
        player = "spotify";
        format = "${dim "♪"}   {dynamic}";
        format-paused = "${dim "♪"}   <i>{dynamic}</i>";
        dynamic-order = [ "title" "artist" ];
        dynamic-separator = "  ·  ";
        title-len = 40;
        artist-len = 22;
        tooltip-format = "{title}\n{artist}\n{album}";
        on-click = "playerctl -p spotify metadata xesam:url | wl-copy";
        on-click-right = "playerctl -p spotify play-pause";
      };

      clock = {
        interval = 60;
        format = "{0:%H:%M}  ${dim "{0:%a %d %b}"}";
        tooltip-format = "{:%A, %d %B %Y}";
      };

      network = {
        format-wifi = "${dim "NET"}   {essid}";
        format-ethernet = "${dim "NET"}   wired";
        format-disconnected = "${dim "NET"}   offline";
        format-alt = "${dim "NET"}   {bandwidthDownBits} ↓  {bandwidthUpBits} ↑";
        tooltip-format = "{ifname}  {ipaddr}/{cidr}\n{essid}  {frequency} GHz  {signalStrength}%";
        interval = 2;
      };

      pulseaudio = {
        format = "${dim "VOL"}   {volume}%";
        format-muted = "${dim "VOL"}   muted";
        max-volume = 150;
        on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
      };

      cpu = {
        format = "${dim "CPU"}   {usage}%";
        format-alt = "${dim "CPU"}   {usage}%  {avg_frequency} GHz";
        states = { warning = 60; critical = 90; };
        interval = 2;
      };

      memory = {
        format = "${dim "MEM"}   {percentage}%";
        format-alt = "${dim "MEM"}   {used:0.1f}/{total:0.1f} G";
        states = { warning = 80; critical = 90; };
      };

      disk = {
        format = "${dim "DSK"}   {percentage_used}%";
        format-alt = "${dim "DSK"}   {used} / {total}";
        states = { warning = 85; critical = 90; };
      };

      battery = {
        format = "${dim "BAT"}   {capacity}%";
        format-charging = "${dim "CHR"}   {capacity}%";
        format-plugged = "${dim "AC"}   {capacity}%";
        states = { warning = 25; critical = 10; };
      };
    };

    style = ''
      * {
        font-family: "Geist", sans-serif;
        font-size: 11pt;
        font-feature-settings: "tnum";
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        color: #dcd7ba;
        background-color: rgba(22, 22, 29, 0.78);
        border: 1px solid rgba(220, 215, 186, 0.08);
        border-radius: 12px;
      }

      #workspaces, #custom-columns, #mpris,
      #network, #pulseaudio, #cpu, #memory, #disk, #battery {
        margin: 5px 0;
        padding: 0 12px;
        border-radius: 8px;
        background-color: rgba(54, 54, 70, 0.45);
      }

      #workspaces { margin-left: 5px; padding: 0 2px; }
      #battery { margin-right: 5px; }
      #custom-columns { color: #957fb8; font-size: 9pt; }
      #clock { padding: 0 12px; font-weight: 600; }

      #workspaces button {
        margin: 2px 1px;
        padding: 0 9px;
        border-radius: 6px;
        color: #727169;
        background: transparent;
      }
      #workspaces button:hover { color: #dcd7ba; background: rgba(84, 84, 109, 0.6); box-shadow: none; }
      #workspaces button.active { color: #16161d; background: #957fb8; }
      #workspaces button.urgent { color: #16161d; background: #e46876; }
      #workspaces button.empty:not(.active) { padding: 0; margin: 0; min-width: 0; font-size: 0; }

      #mpris.playing { color: #7fb4ca; }
      #mpris.paused { color: #9e9b93; }
      #battery.charging { color: #98bb6c; }
      #network.disconnected, #pulseaudio.muted { color: #e46876; }
      .warning { color: #e6c384; }
      .critical { color: #16161d; background-color: #e46876; }

      tooltip { background: #16161d; border: 1px solid #363646; border-radius: 8px; }
      tooltip label { color: #dcd7ba; padding: 4px; }
    '';
  };
}
