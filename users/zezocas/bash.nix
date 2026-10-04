{
  programs.readline = {
    enable = true;
    variables = {
      editing-mode = "vi";
      show-mode-in-prompt = true;
      show-all-if-ambiguous = true;
      menu-complete-display-prefix = true;
      colored-completion-prefix = true;
      completion-ignore-case = true;
      mark-symlinked-directories = true;
      enable-bracketed-paste = true;
    };
    extraConfig = ''
      set vi-ins-mode-string "\1\e[2 q\2"
      set vi-cmd-mode-string "\1\e[2 q\2"

      set keymap vi-insert
      TAB: menu-complete
      "\eZ": menu-complete-backward
      "\eK": history-search-backward
      "\eJ": history-search-forward

      set keymap vi-command
      "?": reverse-search-history
    '';
  };

  programs.bash = {
    enable = true;
    historyControl = [ "erasedups" ];
    historySize = 2000;
    historyFileSize = 4000;
    shellOptions = [ "histappend" "checkwinsize" "globstar" ];

    shellAliases = {
      kys = "poweroff";
      ls = "ls --color=auto";
      euromilhoes = "shuf -i 1-50 -n5 | sort -n | tr '\\n' ' '; printf '+ '; shuf -i 1-12 -n2 | sort -n | tr '\\n' ' '; echo;";
    };

    initExtra = ''
      set -o vi
      export SINGULARITYENV_PS1='(singularity) [\u@\h] \w \$ '

      prompt_git() {
        local branch changes dot
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return
        [ "$branch" = HEAD ] && branch=$(git rev-parse --short HEAD)
        changes=$(git status --porcelain 2>/dev/null)

        if [ -z "$changes" ]; then dot='\[\e[0;32m\]'
        elif grep -q '^[MADRC]' <<< "$changes"; then dot='\[\e[0;33m\]'
        elif grep -q '^.[MD]' <<< "$changes"; then dot='\[\e[0;31m\]'
        else dot='\[\e[0;33m\]'
        fi

        echo " \[\e[1;33m\]($branch)\[\e[0m\] $dot●\[\e[0m\]"
      }

      set_prompt() {
        local code=$? symbol='\[\e[1;32m\]'
        [ $code -ne 0 ] && symbol='\[\e[1;31m\]'
        PS1="\[\e[0;37m\][\[\e[1;35m\]\u\[\e[0;37m\]@\[\e[1;36m\]\h\[\e[0;37m\]]\[\e[0m\] \[\e[1;34m\]\w\[\e[0m\]$(prompt_git)$symbol \$\[\e[0m\] "
      }

      PROMPT_COMMAND=set_prompt
    '';
  };
}
