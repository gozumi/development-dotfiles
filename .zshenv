# Let zsh-autocomplete (sourced in ~/.zshrc) run compinit, not Ubuntu's /etc/zsh/zshrc
skip_global_compinit=1

# nvm setup (completion is loaded in ~/.zshrc)
[ -d $HOME/.nvm ] && export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
. "$HOME/.cargo/env"
