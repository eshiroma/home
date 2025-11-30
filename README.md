# Quick Setup

``` 
install_location="$HOME/local/github.com/eshiroma/home" \
&& sudo apt install -y git make \
&& git clone \
      --depth=1 \
      --recursive \
      "https://github.com/eshiroma/home" "$install_location" \
&& make -C "$install_location"
```

## `.localrc`

Setup will create a `~/.localrc` file for machine-specific settings, e.g.
terminal prompt and tmux pane colors. 

# SSH

Quick setup clones with https for simplicity since the repo is public. In order
to write, this should be converted to SSH:

```
git remote set-url origin git@github.com:eshiroma/home.git
```

Create a new key and upload the `.pub` file at Settings > SSH and GPG keys:

```
ssh-keygen -t ed25519 -C "<key_description>"
```

