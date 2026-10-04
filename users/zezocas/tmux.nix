{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
    extraConfig = ''
      resize_step=5

      set -g update-environment "SSH_AUTH_SOCK LANG LC_CTYPE LC_ALL TERM EDITOR VISUAL PAGER LESS PATH WAYLAND_DISPLAY"
      set -ga terminal-overrides ",*:Tc"

      bind r command-prompt "rename-window %%"

      set -g set-clipboard on
      bind-key -T copy-mode-vi y send -X copy-selection-and-cancel

      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\S+\/)?g?(view|n?vim?x?)(diff)?$'"

      bind ";" split-window -h -c "#{pane_current_path}"
      bind "/" split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"

      bind -n M-C-h if-shell "$is_vim" "send-keys M-h" "resize-pane -L $resize_step"
      bind -n M-C-j if-shell "$is_vim" "send-keys M-j" "resize-pane -D $resize_step"
      bind -n M-C-k if-shell "$is_vim" "send-keys M-k" "resize-pane -U $resize_step"
      bind -n M-C-l if-shell "$is_vim" "send-keys M-l" "resize-pane -R $resize_step"

      bind -n M-h previous-window
      bind -n M-l next-window

      set-window-option -g pane-border-status bottom
      set -g pane-border-format ""

      set -g status-right "%H:%M | %d-%m-%Y "
      set -g status-style fg=colour255

      set -g window-style fg=colour240,bg=default
      set -g window-active-style fg=colour255,bg=default

      set -g pane-border-style fg=colour248
      set -g pane-active-border-style fg=colour248

      set -g message-style fg=colour255
      set -g mode-style bg=colour250,fg=colour0
    '';
  };
}
