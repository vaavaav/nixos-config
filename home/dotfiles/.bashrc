set -o vi                                                  # vi mode
bind -m vi-insert 'TAB:menu-complete'                      # cycle through matches
bind -m vi-insert '"\eZ":menu-complete-backward'           # Cycle backwards
bind 'set show-all-if-ambiguous on'                        # list multiple matches
bind 'set menu-complete-display-prefix on'                 # try to complete and list all
bind 'set colored-completion-prefix on'                    # colorize common prefix
bind 'set completion-ignore-case on'                       # case insensitive completion
bind 'set mark-symlinked-directories on'                   # mark symlinked directories
bind 'set enable-bracketed-paste on'                       # paste as text not commands
bind -m vi-command '"?":reverse-search-history'            # reverse search
bind -m vi-insert '"\eK":history-search-backward'          # backwards search
bind -m vi-insert '"\eJ":history-search-forward'           # forwards search

# Shell options
shopt -s histappend      # append to history file, don't overwrite (fixes multi-terminal clobbering)
shopt -s checkwinsize    # update LINES/COLUMNS after each command
shopt -s globstar        # enable ** recursive globbing

# Alias
alias kys="poweroff"
alias ls="ls --color=auto"
alias euromilhoes="shuf -i 1-50 -n5 | sort -n | tr '\n' ' '; printf '+ '; shuf -i 1-12 -n2 | sort -n | tr '\n' ' '; echo;"

# Environment Vars
export HISTCONTROL=erasedups                      # ignore duplicate commands
export HISTSIZE=2000                              # number of commands to remember in memory
export HISTFILESIZE=4000                          # number of commands to keep in history file
export VISUAL="nvim"
export EDITOR="nvim"
export SINGULARITYENV_PS1='(singularity) [\u@\h] \w \$ '

# Colors - Using a cleaner approach
RED='\[\033[0;31m\]'
GREEN='\[\033[0;32m\]'
YELLOW='\[\033[0;33m\]'
WHITE='\[\033[0;37m\]'
BOLD='\[\033[1m\]'
RESET='\[\033[0m\]'
LIGHT_PURPLE='\[\033[1;35m\]'
LIGHT_CYAN='\[\033[1;36m\]'
LIGHT_BLUE='\[\033[1;34m\]'
LIGHT_YELLOW='\[\033[1;33m\]'
ORANGE='\[\033[0;33m\]'

# Git branch function
git_branch() {
    local branch
    if branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
        if [[ $branch == "HEAD" ]]; then
            branch=$(git rev-parse --short HEAD 2>/dev/null)
        fi
        echo "($branch)"
    fi
}

# Git status indicator - single `git status --porcelain` call instead of three separate git invocations
git_status() {
    git rev-parse --git-dir >/dev/null 2>&1 || return
    local s
    s=$(git status --porcelain 2>/dev/null)

    if [[ -z "$s" ]]; then
        echo "clean"
        return
    fi
    if grep -q '^[MADRC]' <<< "$s"; then
        echo "staged"
        return
    fi
    if grep -q '^.[MD]' <<< "$s"; then
        echo "modified"
        return
    fi
    echo "untracked"
}

# Custom PS1 - Rebuilt to avoid issues with command substitution
set_ps1() {
    local exit_code=$?
    local status_color
    local git_info=""
    local git_stat=""

    # Get git info
    if git rev-parse --git-dir >/dev/null 2>&1; then
        local branch=$(git_branch)
        local status=$(git_status)

        if [[ -n "$branch" ]]; then
            git_info=" ${LIGHT_YELLOW}${branch}${RESET}"
        fi

        case "$status" in
            "staged")    git_stat=" ${YELLOW}●${RESET}" ;;
            "modified")  git_stat=" ${RED}●${RESET}" ;;
            "untracked") git_stat=" ${ORANGE}●${RESET}" ;;
            "clean")     git_stat=" ${GREEN}●${RESET}" ;;
        esac
    fi

    # Set status color
    if [ $exit_code -eq 0 ]; then
        status_color=$GREEN
    else
        status_color=$RED
    fi

    # Build PS1 without command substitutions in the prompt itself
    PS1="${BOLD}${WHITE}[${RESET}${BOLD}${LIGHT_PURPLE}\u${RESET}${BOLD}${WHITE}@${RESET}${BOLD}${LIGHT_CYAN}\h${RESET}${BOLD}${WHITE}]${RESET} ${BOLD}${LIGHT_BLUE}\w${RESET}${git_info}${git_stat}${status_color}${BOLD} \$${RESET} "
}
PROMPT_COMMAND=set_ps1

