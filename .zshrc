# zstyle ':completion:*:*:git:*' script ~/.git-completion.bash

# fpath=(~/.zsh/completion $fpath)

# ---------------------------------------------------------------------------
# Completion (zsh-autocomplete)
#
# zsh-autocomplete runs compinit itself (on the first prompt) and queues any
# compdef/complete calls made before then, so:
#   * never call compinit/bashcompinit in this file
#   * fpath must be final before the plugin is sourced
#   * skip_global_compinit=1 is set in ~/.zshenv to stop Ubuntu's
#     /etc/zsh/zshrc from running compinit first
# ---------------------------------------------------------------------------
export PATH=$HOME/.local/bin:$HOME/.bun/bin:$HOME/.deno/bin:$PATH

# Generated completion scripts live in ~/.zfunc. Each is (re)generated when
# missing/empty or when the tool's binary is newer (i.e. after an upgrade).
fpath=(~/.zfunc $fpath)
[[ -d ~/.zfunc ]] || mkdir -p ~/.zfunc
_zfunc_generate() {  # usage: _zfunc_generate <name> <command> [args...]
  local file=~/.zfunc/_$1 bin=${commands[$2]}; shift
  [[ -n $bin ]] || return 0
  [[ -s $file && $file -nt $bin ]] && return 0
  "$@" >| $file.tmp 2>/dev/null && [[ -s $file.tmp ]] && mv -f $file.tmp $file
  rm -f $file.tmp
}
_zfunc_generate rustup rustup completions zsh
_zfunc_generate cargo  rustup completions zsh cargo
_zfunc_generate bun    bun completions zsh
_zfunc_generate deno   deno completions zsh
unfunction _zfunc_generate

[[ -f ~/packages/zsh-autocomplete/zsh-autocomplete.plugin.zsh ]] &&
  source ~/packages/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# Tab / Shift-Tab open the completion menu instead of inserting the first item
bindkey              '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select

# zsh-autocomplete lists directories before everything else; put
# package.json scripts first for `bun run`.
zstyle ':completion:*:*:bun:*' group-order scripts bin directories files

# nvm only ships a bash completion script, and it runs compinit itself unless
# compinit is already defined. Declare (don't run) compinit so it is left to
# zsh-autocomplete; nvm's `complete` call is then queued by the plugin.
export NVM_DIR=${NVM_DIR:-$HOME/.nvm}
autoload -Uz compinit
for _nvm_comp in $NVM_DIR/bash_completion /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm; do
  [[ -s $_nvm_comp ]] && { source $_nvm_comp; break }
done
unset _nvm_comp

# Set up the prompt

setopt autocd

# set up git prompt
autoload -Uz add-zsh-hook vcs_info

function precmd () {
  add-zsh-hook precmd vcs_info
}


if [[ "$OSTYPE" == "linux-gnu"* && -f /etc/lsb-release ]]; then
  USER_COLOR=208
  PATH_COLOR=178
else
  USER_COLOR=33
  PATH_COLOR=99
fi

zstyle ':vcs_info:git*' formats "%b %m"
setopt PROMPT_SUBST

RPROMPT=%F{242}\$vcs_info_msg_0_
PROMPT="%F{$USER_COLOR}%n@%m %F{$PATH_COLOR}%2~%F{white}"$'\n'"%# "

zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr ' *'
zstyle ':vcs_info:*' stagedstr ' +'
zstyle ':vcs_info:git:*' formats       '(%b%u%c)'
zstyle ':vcs_info:git:*' actionformats '(%b|%a%u%c)'


setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
# bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

if whence dircolors >/dev/null; then
  eval "$(dircolors -b)"
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
else
  export CLICOLOR=1
  zstyle ':completion:*:default' list-colors ''
fi

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

export TZ=Europe/London
# export LANG=en_GB.UTF-8
# export LANGUAGE=en_GB
export DISPLAY=host.docker.internal:0 

alias bat=batcat
alias ls="ls --color=auto"
alias l="ls -al"
alias start-shell-container=$HOME/development/shell-container/start.sh
alias stop-shell-container=$HOME/development/shell-container/stop.sh
alias enter-shell-container=$HOME/development/shell-container/enter.sh
alias gitpush="git push origin && git push gitlab && git push bitbucket"
alias cci-run='circleci pipeline run UMgunUQXZbagsQGQyzddTm 6KLSnLh7AUDJPxcUTrKabV --pipeline-definition-id 34b63115-88ae-486d-8830-f7bca7c9ee7d --config-branch "$(git branch --show-current)" --checkout-branch "$(git branch --show-current)"'
alias cci-list='circleci pipeline list 2b0d1073-c3ef-4191-b416-262232cfe1d4'

get-ip-address() {
  if command -v ip >/dev/null 2>&1; then
    # Linux: prints "iface IP"
    ip -4 -o addr show scope global | awk '{split($4,a,"/"); print $2, a[1]}'
  elif command -v ifconfig >/dev/null 2>&1; then
    # macOS/BSD: associate inet lines with the current interface
    ifconfig | awk '/^[^ \t]/ {iface=$1; sub(/:$/,"",iface)} /inet / && $2 != "127.0.0.1" {print iface, $2}'
  else
    echo "No suitable network tool found (ip or ifconfig)" >&2
    return 1
  fi
}

pr-checks() {
  gh pr checks "$1" --watch
}

cci-cancel-all() {
  local TOKEN=$(awk -F': *' '$1=="token"{print $2}' ~/.circleci/cli.yml)
  local API=https://circleci.com/api/v2
  local PROJECT=circleci/UMgunUQXZbagsQGQyzddTm/6KLSnLh7AUDJPxcUTrKabV

  curl -s -G -H "Circle-Token: $TOKEN" "$API/project/$PROJECT/pipeline" \
    --data-urlencode "branch=$(git branch --show-current)" \
    | jq -r '.items[].id' \
    | while read -r pipeline; do
        curl -s -H "Circle-Token: $TOKEN" "$API/pipeline/$pipeline/workflow" \
          | jq -r '.items[] | select(.status == "running" or .status == "failing" or .status == "on_hold") | .id'
      done \
    | while read -r workflow; do
        echo "cancelling $workflow"
        curl -s -X POST -H "Circle-Token: $TOKEN" "$API/workflow/$workflow/cancel"
        echo
      done
}

# Check recent CircleCI pipelines (with workflow status) for a branch (defaults to current git branch)
cci-pipelines() {
  local org_id project_id branch token_file="$HOME/.circleci/cli.yml"

  if [[ ! -f "$token_file" ]]; then
    echo "No CircleCI token found at $token_file" >&2
    return 1
  fi
  local token
  token=$(awk '/^token:/ {print $2}' "$token_file")

  local vcs_url
  vcs_url=$(curl -s -H "Circle-Token: $token" \
    "https://circleci.com/api/v1.1/projects" \
    | jq -r '.[0].vcs_url')
  org_id=$(basename "$(dirname "$vcs_url")")
  project_id=$(basename "$vcs_url")

  branch="${1:-$(git branch --show-current)}"

  curl -s -H "Circle-Token: $token" \
    "https://circleci.com/api/v2/project/circleci/$org_id/$project_id/pipeline?branch=$(printf '%s' "$branch" | jq -sRr @uri)" \
    | jq -r '.items[] | "\(.id)\t\(.number)\t\(.created_at)\t\(.trigger_parameters.git.commit_message // "" | split("\n")[0])"' \
    | while IFS=$'\t' read -r pipeline_id number created_at commit_message; do
      local workflows
      workflows=$(curl -s -H "Circle-Token: $token" \
        "https://circleci.com/api/v2/pipeline/$pipeline_id/workflow" \
        | jq -r '[.items[] | "\(.name):\(.status)" + (if .canceled_by and .status != "canceled" then " (cancel pending)" else "" end)] | join(", ")')
      [[ -z "$workflows" ]] && workflows="(no workflows)"
      if (( ${#commit_message} > 60 )); then
        commit_message="${commit_message[1,60]}..."
      fi
      echo "$number\t$workflows\t$created_at\t$commit_message"
    done
}

cci-cancel() {
  local pipeline_number="$1" org_id project_id token_file="$HOME/.circleci/cli.yml"

  if [[ -z "$pipeline_number" ]]; then
    echo "Usage: cci-cancel <pipeline-number>" >&2
    return 1
  fi
  if [[ ! -f "$token_file" ]]; then
    echo "No CircleCI token found at $token_file" >&2
    return 1
  fi
  local token
  token=$(awk '/^token:/ {print $2}' "$token_file")

  local vcs_url
  vcs_url=$(curl -s -H "Circle-Token: $token" \
    "https://circleci.com/api/v1.1/projects" \
    | jq -r '.[0].vcs_url')
  org_id=$(basename "$(dirname "$vcs_url")")
  project_id=$(basename "$vcs_url")

  local pipeline_id
  pipeline_id=$(curl -s -H "Circle-Token: $token" \
    "https://circleci.com/api/v2/project/circleci/$org_id/$project_id/pipeline/$pipeline_number" \
    | jq -r '.id')

  if [[ -z "$pipeline_id" || "$pipeline_id" == "null" ]]; then
    echo "Could not resolve pipeline $pipeline_number" >&2
    return 1
  fi

  curl -s -H "Circle-Token: $token" \
    "https://circleci.com/api/v2/pipeline/$pipeline_id/workflow" \
    | jq -r '.items[].id' \
    | while read -r workflow_id; do
      echo "Cancelling workflow $workflow_id"
      curl -s -X POST -H "Circle-Token: $token" \
        "https://circleci.com/api/v2/workflow/$workflow_id/cancel" | jq .
    done
}

# Load nvm on macOS with Homebrew
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# Maintain a stable nvm "current" symlink so tools (e.g. SonarLint) can point at it
export NVM_SYMLINK_CURRENT=true

# Auto-start the Docker daemon in sandboxed dev containers that have no systemd
# (PID 1 is sshd) and where /etc/init.d/docker's `ulimit -Hn` call fails, so
# `service docker start` doesn't work. Scoped to that exact situation so this
# is a no-op on macOS (Docker Desktop) or any systemd-managed Linux box.
no_systemd=true
if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
  no_systemd=false
fi
if command -v dockerd >/dev/null 2>&1 && [ "$no_systemd" = true ] && ! pgrep -x dockerd >/dev/null 2>&1; then
  sudo mkdir -p /var/log/docker
  sudo bash -c 'nohup dockerd >> /var/log/docker/dockerd.log 2>&1 & disown'
fi
unset no_systemd
