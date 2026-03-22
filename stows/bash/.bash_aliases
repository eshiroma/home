alias cdh='cd ~/local/github.com/eshiroma/home'

# Source shell functions (sourced, not executed, so they can modify current shell state).
for f in "${HOME}/.scripts/functions/"*; do
  [ -f "$f" ] && source "$f"
done
unset f
