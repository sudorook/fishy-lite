# SPDX-FileCopyrightText: 2017 - 2024 sudorook <daemon@nullcodon.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-License-Identifier: MIT
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

#
# Zsh configuration options copied from oh-my-zsh. Copied over:
#  - completions.zsh
#  - grep.zsh
#  - history.zsh
#  - key-bindings.zsh
#  - misc.zsh
#  - spectrum.zsh
#  - termsupport.zsh
#  - theme-and-appearance.zsh
#

autoload -U compaudit compinit


#
# from lib/completion.zsh
#

# fixme - the load process here seems a bit bizarre
zmodload -i zsh/complist

WORDCHARS=''

unsetopt menu_complete   # do not autoselect the first completion entry
unsetopt flowcontrol
setopt auto_menu         # show completion menu on successive tab press
setopt complete_in_word
setopt always_to_end

# should this be in keybindings?
bindkey -M menuselect '^o' accept-and-infer-next-history
zstyle ':completion:*:*:*:*:*' menu select

# case insensitive (all), partial-word and substring completion
if [[ "$CASE_SENSITIVE" = true ]]; then
  zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'
else
  if [[ "$HYPHEN_INSENSITIVE" = true ]]; then
    zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' 'r:|=*' 'l:|=* r:|=*'
  else
    zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
  fi
fi
unset CASE_SENSITIVE HYPHEN_INSENSITIVE

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

if [[ "$OSTYPE" = solaris* ]]; then
  zstyle ':completion:*:*:*:*:processes' command "ps -u $USERNAME -o pid,user,comm"
else
  zstyle ':completion:*:*:*:*:processes' command "ps -u $USERNAME -o pid,user,comm -w -w"
fi

# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path $ZSH_CACHE_DIR

# Don't complete uninteresting users
zstyle ':completion:*:*:*:users' ignored-patterns \
        adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
        clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
        gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
        ldap lp mail mailman mailnull man messagebus mldonkey mysql nagios \
        named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
        operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
        rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
        usbmux uucp vcsa wwwrun xfs '_*'

# ... unless we really want to.
zstyle '*' single-ignored show

if [[ ${COMPLETION_WAITING_DOTS:-false} != false ]]; then
  expand-or-complete-with-dots() {
    # use $COMPLETION_WAITING_DOTS either as toggle or as the sequence to show
    [[ $COMPLETION_WAITING_DOTS = true ]] && COMPLETION_WAITING_DOTS="%F{red}…%f"
    # turn off line wrapping and print prompt-expanded "dot" sequence
    printf '\e[?7l%s\e[?7h' "${(%)COMPLETION_WAITING_DOTS}"
    zle expand-or-complete
    zle redisplay
  }
  zle -N expand-or-complete-with-dots
  # Set the function as the default tab completion widget
  bindkey -M emacs "^I" expand-or-complete-with-dots
  bindkey -M viins "^I" expand-or-complete-with-dots
  bindkey -M vicmd "^I" expand-or-complete-with-dots
fi

# automatically load bash completion functions
autoload -U +X bashcompinit && bashcompinit


#
# from lib/grep.zsh
#

__GREP_CACHE_FILE="$ZSH_CACHE_DIR"/grep-alias

# See if there's a cache file modified in the last day
__GREP_ALIAS_CACHES=("$__GREP_CACHE_FILE"(Nm-1))
if [[ -n "$__GREP_ALIAS_CACHES" ]]; then
    source "$__GREP_CACHE_FILE"
else
    grep-flags-available() {
        command grep "$@" "" &>/dev/null <<< ""
    }

    # Ignore these folders (if the necessary grep flags are available)
    EXC_FOLDERS="{.bzr,CVS,.git,.hg,.svn,.idea,.tox}"

    # Check for --exclude-dir, otherwise check for --exclude. If --exclude
    # isn't available, --color won't be either (they were released at the same
    # time (v2.5): https://git.savannah.gnu.org/cgit/grep.git/tree/NEWS?id=1236f007
    if grep-flags-available --color=auto --exclude-dir=.cvs; then
        GREP_OPTIONS="--color=auto --exclude-dir=$EXC_FOLDERS"
    elif grep-flags-available --color=auto --exclude=.cvs; then
        GREP_OPTIONS="--color=auto --exclude=$EXC_FOLDERS"
    fi

    if [[ -n "$GREP_OPTIONS" ]]; then
        # export grep, egrep and fgrep settings
        alias grep="grep $GREP_OPTIONS"
        alias egrep="grep -E $GREP_OPTIONS"
        alias fgrep="grep -F $GREP_OPTIONS"

        # write to cache file if cache directory is writable
        if [[ -w "$ZSH_CACHE_DIR" ]]; then
            alias -L grep egrep fgrep >| "$__GREP_CACHE_FILE"
        fi
    fi

    # Clean up
    unset GREP_OPTIONS EXC_FOLDERS
    unfunction grep-flags-available
fi

unset __GREP_CACHE_FILE __GREP_ALIAS_CACHES


#
# from lib/history.zsh
#

## History wrapper
function omz_history {
  local clear list
  zparseopts -E c=clear l=list

  if [[ -n "$clear" ]]; then
    # if -c provided, clobber the history file
    echo -n >| "$HISTFILE"
    fc -p "$HISTFILE"
    echo >&2 History file deleted.
  elif [[ -n "$list" ]]; then
    # if -l provided, run as if calling `fc' directly
    builtin fc "$@"
  else
    # unless a number is provided, show all history events (starting from 1)
    [[ ${@[-1]-} = *[0-9]* ]] && builtin fc -l "$@" || builtin fc -l "$@" 1
  fi
}

# Timestamp format
case ${HIST_STAMPS-} in
  "mm/dd/yyyy") alias history='omz_history -f' ;;
  "dd.mm.yyyy") alias history='omz_history -E' ;;
  "yyyy-mm-dd") alias history='omz_history -i' ;;
  "") alias history='omz_history' ;;
  *) alias history="omz_history -t '$HIST_STAMPS'" ;;
esac

## History file configuration
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
[ "$HISTSIZE" -lt 50000 ] && HISTSIZE=50000
[ "$SAVEHIST" -lt 10000 ] && SAVEHIST=10000

## History command configuration
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data


#
# from lib/key-bindings.zsh
#

# Make sure that the terminal is in application mode when zle is active, since
# only then values from $terminfo are valid
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init() {
    echoti smkx
  }
  function zle-line-finish() {
    echoti rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

# Use emacs key bindings
bindkey -e

# [PageUp] - Up a line of history
if [[ -n "${terminfo[kpp]}" ]]; then
  bindkey -M emacs "${terminfo[kpp]}" up-line-or-history
  bindkey -M viins "${terminfo[kpp]}" up-line-or-history
  bindkey -M vicmd "${terminfo[kpp]}" up-line-or-history
fi
# [PageDown] - Down a line of history
if [[ -n "${terminfo[knp]}" ]]; then
  bindkey -M emacs "${terminfo[knp]}" down-line-or-history
  bindkey -M viins "${terminfo[knp]}" down-line-or-history
  bindkey -M vicmd "${terminfo[knp]}" down-line-or-history
fi

# Start typing + [Up-Arrow] - fuzzy find history forward
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search

bindkey -M emacs "^[[A" up-line-or-beginning-search
bindkey -M viins "^[[A" up-line-or-beginning-search
bindkey -M vicmd "^[[A" up-line-or-beginning-search
if [[ -n "${terminfo[kcuu1]}" ]]; then
  bindkey -M emacs "${terminfo[kcuu1]}" up-line-or-beginning-search
  bindkey -M viins "${terminfo[kcuu1]}" up-line-or-beginning-search
  bindkey -M vicmd "${terminfo[kcuu1]}" up-line-or-beginning-search
fi

# Start typing + [Down-Arrow] - fuzzy find history backward
autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -M emacs "^[[B" down-line-or-beginning-search
bindkey -M viins "^[[B" down-line-or-beginning-search
bindkey -M vicmd "^[[B" down-line-or-beginning-search
if [[ -n "${terminfo[kcud1]}" ]]; then
  bindkey -M emacs "${terminfo[kcud1]}" down-line-or-beginning-search
  bindkey -M viins "${terminfo[kcud1]}" down-line-or-beginning-search
  bindkey -M vicmd "${terminfo[kcud1]}" down-line-or-beginning-search
fi

# [Home] - Go to beginning of line
if [[ -n "${terminfo[khome]}" ]]; then
  bindkey -M emacs "${terminfo[khome]}" beginning-of-line
  bindkey -M viins "${terminfo[khome]}" beginning-of-line
  bindkey -M vicmd "${terminfo[khome]}" beginning-of-line
fi
# [End] - Go to end of line
if [[ -n "${terminfo[kend]}" ]]; then
  bindkey -M emacs "${terminfo[kend]}"  end-of-line
  bindkey -M viins "${terminfo[kend]}"  end-of-line
  bindkey -M vicmd "${terminfo[kend]}"  end-of-line
fi

# [Shift-Tab] - move through the completion menu backwards
if [[ -n "${terminfo[kcbt]}" ]]; then
  bindkey -M emacs "${terminfo[kcbt]}" reverse-menu-complete
  bindkey -M viins "${terminfo[kcbt]}" reverse-menu-complete
  bindkey -M vicmd "${terminfo[kcbt]}" reverse-menu-complete
fi

# [Backspace] - delete backward
bindkey -M emacs '^?' backward-delete-char
bindkey -M viins '^?' backward-delete-char
bindkey -M vicmd '^?' backward-delete-char
# [Delete] - delete forward
if [[ -n "${terminfo[kdch1]}" ]]; then
  bindkey -M emacs "${terminfo[kdch1]}" delete-char
  bindkey -M viins "${terminfo[kdch1]}" delete-char
  bindkey -M vicmd "${terminfo[kdch1]}" delete-char
else
  bindkey -M emacs "^[[3~" delete-char
  bindkey -M viins "^[[3~" delete-char
  bindkey -M vicmd "^[[3~" delete-char

  bindkey -M emacs "^[3;5~" delete-char
  bindkey -M viins "^[3;5~" delete-char
  bindkey -M vicmd "^[3;5~" delete-char
fi

# [Ctrl-Delete] - delete whole forward-word
bindkey -M emacs '^[[3;5~' kill-word
bindkey -M viins '^[[3;5~' kill-word
bindkey -M vicmd '^[[3;5~' kill-word

# [Ctrl-RightArrow] - move forward one word
bindkey -M emacs '^[[1;5C' forward-word
bindkey -M viins '^[[1;5C' forward-word
bindkey -M vicmd '^[[1;5C' forward-word
# [Ctrl-LeftArrow] - move backward one word
bindkey -M emacs '^[[1;5D' backward-word
bindkey -M viins '^[[1;5D' backward-word
bindkey -M vicmd '^[[1;5D' backward-word


bindkey '\ew' kill-region                             # [Esc-w] - Kill from the cursor to the mark
bindkey -s '\el' 'ls\n'                               # [Esc-l] - run command: ls
bindkey '^r' history-incremental-search-backward      # [Ctrl-r] - Search backward incrementally for a specified string. The string may begin with ^ to anchor the search to the beginning of the line.
bindkey ' ' magic-space                               # [Space] - don't do history expansion


# Edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# file rename magick
bindkey "^[m" copy-prev-shell-word

# consider emacs keybindings:

#bindkey -e  ## emacs key bindings
#
#bindkey '^[[A' up-line-or-search
#bindkey '^[[B' down-line-or-search
#bindkey '^[^[[C' emacs-forward-word
#bindkey '^[^[[D' emacs-backward-word
#
#bindkey -s '^X^Z' '%-^M'
#bindkey '^[e' expand-cmd-path
#bindkey '^[^I' reverse-menu-complete
#bindkey '^X^N' accept-and-infer-next-history
#bindkey '^W' kill-region
#bindkey '^I' complete-word
## Fix weird sequence that rxvt produces
#bindkey -s '^[[Z' '\t'
#


#
# from lib/misc.zsh
#

autoload -Uz is-at-least

# *-magic is known buggy in some versions; disable if so
if [[ $DISABLE_MAGIC_FUNCTIONS != true ]]; then
  for d in $fpath; do
    if [[ -e "$d/url-quote-magic" ]]; then
      if is-at-least 5.1; then
        autoload -Uz bracketed-paste-magic
        zle -N bracketed-paste bracketed-paste-magic
      fi
      autoload -Uz url-quote-magic
      zle -N self-insert url-quote-magic
    break
    fi
  done
fi

setopt multios              # enable redirect to multiple streams: echo >file1 >file2
setopt long_list_jobs       # show long list format job notifications
setopt interactivecomments  # recognize comments

# define pager dependant on what is available (less or more)
if (( ${+commands[less]} )); then
  env_default 'PAGER' 'less'
  env_default 'LESS' '-R'
elif (( ${+commands[more]} )); then
  env_default 'PAGER' 'more'
fi

## super user alias
alias _='sudo '

## more intelligent acking for ubuntu users and no alias for users without ack
if (( $+commands[ack-grep] )); then
  alias afind='ack-grep -il'
elif (( $+commands[ack] )); then
  alias afind='ack -il'
fi


#
# from lib/spectrum.zsh
#

typeset -AHg FX FG BG

FX=(
  reset     "%{[00m%}"
  bold      "%{[01m%}" no-bold      "%{[22m%}"
  dim       "%{[02m%}" no-dim       "%{[22m%}"
  italic    "%{[03m%}" no-italic    "%{[23m%}"
  underline "%{[04m%}" no-underline "%{[24m%}"
  blink     "%{[05m%}" no-blink     "%{[25m%}"
  reverse   "%{[07m%}" no-reverse   "%{[27m%}"
)

for color in {000..255}; do
  FG[$color]="%{[38;5;${color}m%}"
  BG[$color]="%{[48;5;${color}m%}"
done

# Show all 256 colors with color number
function spectrum_ls() {
  setopt localoptions nopromptsubst
  local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris}
  for code in {000..255}; do
    print -P -- "$code: ${FG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
  done
}

# Show all 256 colors where the background is set to specific color
function spectrum_bls() {
  setopt localoptions nopromptsubst
  local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris}
  for code in {000..255}; do
    print -P -- "$code: ${BG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
  done
}


#
# from lib/termsupport.zsh
#

# Set terminal window and tab/icon title
#
# usage: title short_tab_title [long_window_title]
#
# See: http://www.faqs.org/docs/Linux-mini/Xterm-Title.html#ss3.1
# Fully supports screen, iterm, and probably most modern xterm and rxvt
# (In screen, only short_tab_title is used)
# Limited support for Apple Terminal (Terminal can't set window and tab separately)
function title {
  setopt localoptions nopromptsubst

  # Don't set the title if inside emacs, unless using vterm
  [[ -n "${INSIDE_EMACS:-}" && "$INSIDE_EMACS" != vterm ]] && return

  # if $2 is unset use $1 as default
  # if it is set and empty, leave it as is
  : ${2=$1}

  case "$TERM" in
    cygwin|xterm*|putty*|rxvt*|konsole*|ansi|mlterm*|alacritty|st*|foot*|contour*)
      print -Pn "\e]2;${2:q}\a" # set window name
      print -Pn "\e]1;${1:q}\a" # set tab name
      ;;
    screen*|tmux*)
      print -Pn "\ek${1:q}\e\\" # set screen hardstatus
      ;;
    *)
      if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
        print -Pn "\e]2;${2:q}\a" # set window name
        print -Pn "\e]1;${1:q}\a" # set tab name
      else
        # Try to use terminfo to set the title if the feature is available
        if (( ${+terminfo[fsl]} && ${+terminfo[tsl]} )); then
          print -Pn "${terminfo[tsl]}$1${terminfo[fsl]}"
        fi
      fi
      ;;
  esac
}

ZSH_THEME_TERM_TAB_TITLE_IDLE="%15<..<%~%<<" #15 char left truncated PWD
ZSH_THEME_TERM_TITLE_IDLE="%n@%m:%~"
# Avoid duplication of directory in terminals with independent dir display
if [[ "$TERM_PROGRAM" == Apple_Terminal ]]; then
  ZSH_THEME_TERM_TITLE_IDLE="%n@%m"
fi

# Runs before showing the prompt
function omz_termsupport_precmd {
  [[ "${DISABLE_AUTO_TITLE:-}" != true ]] || return
  title "$ZSH_THEME_TERM_TAB_TITLE_IDLE" "$ZSH_THEME_TERM_TITLE_IDLE"
}

# Runs before executing the command
function omz_termsupport_preexec {
  [[ "${DISABLE_AUTO_TITLE:-}" != true ]] || return

  emulate -L zsh
  setopt extended_glob

  # split command into array of arguments
  local -a cmdargs
  cmdargs=("${(z)2}")
  # if running fg, extract the command from the job description
  if [[ "${cmdargs[1]}" = fg ]]; then
    # get the job id from the first argument passed to the fg command
    local job_id jobspec="${cmdargs[2]#%}"
    # logic based on jobs arguments:
    # http://zsh.sourceforge.net/Doc/Release/Jobs-_0026-Signals.html#Jobs
    # https://www.zsh.org/mla/users/2007/msg00704.html
    case "$jobspec" in
      <->) # %number argument:
        # use the same <number> passed as an argument
        job_id=${jobspec} ;;
      ""|%|+) # empty, %% or %+ argument:
        # use the current job, which appears with a + in $jobstates:
        # suspended:+:5071=suspended (tty output)
        job_id=${(k)jobstates[(r)*:+:*]} ;;
      -) # %- argument:
        # use the previous job, which appears with a - in $jobstates:
        # suspended:-:6493=suspended (signal)
        job_id=${(k)jobstates[(r)*:-:*]} ;;
      [?]*) # %?string argument:
        # use $jobtexts to match for a job whose command *contains* <string>
        job_id=${(k)jobtexts[(r)*${(Q)jobspec}*]} ;;
      *) # %string argument:
        # use $jobtexts to match for a job whose command *starts with* <string>
        job_id=${(k)jobtexts[(r)${(Q)jobspec}*]} ;;
    esac

    # override preexec function arguments with job command
    if [[ -n "${jobtexts[$job_id]}" ]]; then
      1="${jobtexts[$job_id]}"
      2="${jobtexts[$job_id]}"
    fi
  fi

  # cmd name only, or if this is sudo or ssh, the next cmd
  local CMD="${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}"
  local LINE="${2:gs/%/%%}"

  title "$CMD" "%100>...>${LINE}%<<"
}

autoload -Uz add-zsh-hook

if [[ -z "$INSIDE_EMACS" || "$INSIDE_EMACS" = vterm ]]; then
  add-zsh-hook precmd omz_termsupport_precmd
  add-zsh-hook preexec omz_termsupport_preexec
fi

# Keep terminal emulator's current working directory correct,
# even if the current working directory path contains symbolic links
#
# References:
# - Apple's Terminal.app: https://superuser.com/a/315029
# - iTerm2: https://iterm2.com/documentation-escape-codes.html (iTerm2 Extension / CurrentDir+RemoteHost)
# - Konsole: https://bugs.kde.org/show_bug.cgi?id=327720#c1
# - libvte (gnome-terminal, mate-terminal, …): https://bugzilla.gnome.org/show_bug.cgi?id=675987#c14
#   Apparently it had a bug before ~2012 were it would display the unknown OSC 7 code
#
# As of May 2021 mlterm, PuTTY, rxvt, screen, termux & xterm simply ignore the unknown OSC.

# Don't define the function if we're inside Emacs or in an SSH session (#11696)
if [[ -n "$INSIDE_EMACS" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
  return
fi

# Don't define the function if we're in an unsupported terminal
case "$TERM" in
  # all of these either process OSC 7 correctly or ignore entirely
  xterm*|putty*|rxvt*|konsole*|mlterm*|alacritty|screen*|tmux*) ;;
  contour*|foot*) ;;
  *)
    # Terminal.app and iTerm2 process OSC 7 correctly
    case "$TERM_PROGRAM" in
      Apple_Terminal|iTerm.app) ;;
      *) return ;;
    esac ;;
esac

# Emits the control sequence to notify many terminal emulators
# of the cwd
#
# Identifies the directory using a file: URI scheme, including
# the host name to disambiguate local vs. remote paths.
function omz_termsupport_cwd {
  # Percent-encode the host and path names.
  local URL_HOST URL_PATH
  URL_HOST="$(omz_urlencode -P $HOST)" || return 1
  URL_PATH="$(omz_urlencode -P $PWD)" || return 1

  # Konsole errors if the HOST is provided
  [[ -z "$KONSOLE_PROFILE_NAME" && -z "$KONSOLE_DBUS_SESSION"  ]] || URL_HOST=""

  # common control sequence (OSC 7) to set current host and path
  printf "\e]7;file://%s%s\e\\" "${URL_HOST}" "${URL_PATH}"
}

# Use a precmd hook instead of a chpwd hook to avoid contaminating output
# i.e. when a script or function changes directory without `cd -q`, chpwd
# will be called the output may be swallowed by the script or function.
add-zsh-hook precmd omz_termsupport_cwd


#
# from lib/theme-and-appearance.zsh
#

# Sets color variable such as $fg, $bg, $color and $reset_color
autoload -U colors && colors

# Expand variables and commands in PROMPT variables
setopt prompt_subst

# Prompt function theming defaults
ZSH_THEME_GIT_PROMPT_PREFIX="git:("   # Beginning of the git prompt, before the branch name
ZSH_THEME_GIT_PROMPT_SUFFIX=")"       # End of the git prompt
ZSH_THEME_GIT_PROMPT_DIRTY="*"        # Text to display if the branch is dirty
ZSH_THEME_GIT_PROMPT_CLEAN=""         # Text to display if the branch is clean
ZSH_THEME_RUBY_PROMPT_PREFIX="("
ZSH_THEME_RUBY_PROMPT_SUFFIX=")"


# Use diff --color if available
if command diff --color /dev/null{,} &>/dev/null; then
  function diff {
    command diff --color "$@"
  }
fi

# Don't set ls coloring if disabled
[[ "$DISABLE_LS_COLORS" != true ]] || return 0

# Default coloring for BSD-based ls
export LSCOLORS="Gxfxcxdxbxegedabagacad"

# Default coloring for GNU-based ls
if [[ -z "$LS_COLORS" ]]; then
  # Define LS_COLORS via dircolors if available. Otherwise, set a default
  # equivalent to LSCOLORS (generated via https://geoff.greer.fm/lscolors)
  if (( $+commands[dircolors] )); then
    [[ -f "$HOME/.dircolors" ]] \
      && source <(dircolors -b "$HOME/.dircolors") \
      || source <(dircolors -b)
  else
    export LS_COLORS="di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
  fi
fi

function test-ls-args {
  local cmd="$1"          # ls, gls, colorls, ...
  local args="${@[2,-1]}" # arguments except the first one
  command "$cmd" "$args" /dev/null &>/dev/null
}

# Find the option for using colors in ls, depending on the version
case "$OSTYPE" in
  netbsd*)
    # On NetBSD, test if `gls` (GNU ls) is installed (this one supports colors);
    # otherwise, leave ls as is, because NetBSD's ls doesn't support -G
    test-ls-args gls --color && alias ls='gls --color=tty'
    ;;
  openbsd*)
    # On OpenBSD, `gls` (ls from GNU coreutils) and `colorls` (ls from base,
    # with color and multibyte support) are available from ports.
    # `colorls` will be installed on purpose and can't be pulled in by installing
    # coreutils (which might be installed for ), so prefer it to `gls`.
    test-ls-args gls --color && alias ls='gls --color=tty'
    test-ls-args colorls -G && alias ls='colorls -G'
    ;;
  (darwin|freebsd)*)
    # This alias works by default just using $LSCOLORS
    test-ls-args ls -G && alias ls='ls -G'
    # Only use GNU ls if installed and there are user defaults for $LS_COLORS,
    # as the default coloring scheme is not very pretty
    zstyle -t ':omz:lib:theme-and-appearance' gnu-ls \
      && test-ls-args gls --color \
      && alias ls='gls --color=tty'
    ;;
  *)
    if test-ls-args ls --color; then
      alias ls='ls --color=tty'
    elif test-ls-args ls -G; then
      alias ls='ls -G'
    fi
    ;;
esac

unfunction test-ls-args


#
# Zsh theme emulating the Fish shell's default prompt. Identical to one
# provided in oh-my-zsh, except:
#  - remove 'local' from setting colors
#  - only display 'user ~>', not 'user@host ~>' in the prompt
#  - add git prompt to RPROMPT
#  - add battery gauge to RPROMPT
#

_fishy_collapsed_wd() {
  local i pwd
  pwd=("${(s:/:)PWD/#$HOME/~}")
  if (( $#pwd > 1 )); then
    for i in {1..$(($#pwd-1))}; do
      if [[ "$pwd[$i]" = .* ]]; then
        pwd[$i]="${${pwd[$i]}[1,2]}"
      else
        pwd[$i]="${${pwd[$i]}[1]}"
      fi
    done
  fi
  echo "${(j:/:)pwd}"
}

user_color='cyan'; [ $UID -eq 0 ] && user_color='red';
PROMPT='%{$fg[$user_color]%}%n %{$reset_color%}$(_fishy_collapsed_wd)%{$reset_color%}%(!.#.>) '
PROMPT2='%{$fg[red]%}\ %{$reset_color%}'

# Add empty copies of functions defined in battery-gauge.zsh and git-prompt.zsh
# if their definitions aren't sourced.
if ! typeset -f git_prompt_info >/dev/null && \
   ! typeset -f git_prompt_status >/dev/null; then
  local git_prompt_status () {}
  local git_prompt_info () {}
fi
if ! typeset -f battery_level_gauge >/dev/null; then
  local battery_level_gauge () {}
fi
if ! typeset -f battery_level_blockgauge >/dev/null; then
  local battery_level_blockgauge () {}
fi
if ! typeset -f battery_level_circlegauge >/dev/null; then
  local battery_level_circlegauge () {}
fi
if ! typeset -f battery_level_icongauge >/dev/null; then
  local battery_level_icongauge () {}
fi
if ! typeset -f battery_pct_prompt >/dev/null; then
  local battery_pct_prompt () {}
fi
if ! typeset -f battery_charging >/dev/null; then
  local battery_charging () {}
fi

return_status="%{$fg_bold[red]%}%(?..%?)%{$reset_color%}"
RPROMPT="${RPROMPT}"'${return_status}%{$reset_color%}$(git_prompt_info)$(git_prompt_status)%{$reset_color%}$(battery_level_gauge)$(battery_level_blockgauge)$(battery_level_circlegauge)$(battery_level_icongauge)$(battery_pct_prompt)$(battery_charging)%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX=" "
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg_bold[green]%}+"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg_bold[blue]%}!"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg_bold[red]%}-"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg_bold[magenta]%}>"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg_bold[yellow]%}#"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[cyan]%}?"
