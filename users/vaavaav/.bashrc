set -o vi                                         # vi mode
bind 'TAB:menu-complete'                          # cycle through matches
bind '"\eZ":menu-complete-backward'               # Cycle backwards
bind 'set show-all-if-ambiguous on'               # list multiple matches
bind 'set menu-complete-display-prefix on'        # try to complete and list all
bind 'set colored-completion-prefix on'           # colorize common prefix
bind 'set completion-ignore-case on'              # case insensitive completion
bind 'set mark-symlinked-directories on'          # mark symlinked directories
bind 'set enable-bracketed-paste on'              # paste as text not commands
bind -m vi-command '"?":reverse-search-history'   # reverse search
bind -m vi-insert '"\eK":history-search-backward' # backwards search
bind -m vi-insert '"\eJ":history-search-forward'  # forwards search

# Alias
alias kys="poweroff"
alias ls="ls --color=auto"

# Environment Vars
export HISTCONTROL=erasedups                      # ignore duplicate commands
export HISTSIZE=2000                              # number of commands to remember in history
export VISUAL="nvim"
export EDITOR="nvim"
export TERM="xterm-256color"

# FZF integration
eval "$(fzf --bash)"
export FZF_DEFAULT_COMMAND='fd --hidden --exclude .git'
export FZF_CTRL_T_OPTS='--preview "bat --style=numbers --color=always -n --line-range :500 {}"' 
export FZF_ALT_T_OPTS='--preview "bat --style=numbers --color=always -n --line-range :500 {}"'
export FZF_DEFAULT_OPTS='--border --style=minimal'
bind -x '"\C-f": fzf-file-widget'
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

# Git status indicator - Returns plain text, coloring handled in PS1
git_status() {
    git rev-parse --git-dir >/dev/null 2>&1 || return
    # Staged changes
    if ! git diff-index --quiet --cached HEAD --; then
        echo "staged"
        return
    fi
    # Unstaged changes
    if ! git diff-files --quiet --ignore-submodules --; then
        echo "modified"
        return
    fi
    # Untracked files
    if git ls-files --others --exclude-standard --directory -z | grep -q .; then
        echo "untracked"
        return
    fi
    # Clean repo
    echo "clean"
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
            "staged")   git_stat=" ${YELLOW}●${RESET}" ;;
            "modified") git_stat=" ${RED}●${RESET}" ;;
            "untracked") git_stat=" ${RED}●${RESET}" ;;
            "clean")    git_stat=" ${GREEN}●${RESET}" ;;
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
