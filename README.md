### 🧰 Setup

```bash
# 1. Create a bare Git repository for the dotfiles metadata
git init --bare "$HOME/.dotfiles"

# 2. Add the dot alias permanently
echo "alias dot='/usr/bin/git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME'" >> ~/.bashrc

# 3. Reload the shell configuration
source ~/.bashrc
```

For Zsh, use `~/.zshrc` instead of `~/.bashrc`.

You can now use `dot` like a normal Git command:

```bash
dot status
dot add .bashrc .zshrc
dot commit -m "Initial commit"

dot remote add origin git@github.com:xiliumz/dotfiles.git
dot push -u origin main
```

---

### 💡 Hide Untracked Files

Because the working tree is your entire home directory, Git would otherwise show every untracked file in `$HOME`.

```bash
dot config --local status.showUntrackedFiles no
```

---

### 📦 Adding a Repository as a Submodule

For configuration that lives in its own Git repository, such as Neovim:

```bash
dot submodule add git@github.com:xiliumz/nvim.git .config/nvim
dot commit -m "Add nvim submodule"
dot push
```

The parent dotfiles repository stores the exact commit of the Neovim repository that should be used.

---

### 💻 Setup on a New Machine

```bash
# Clone the bare dotfiles repository
git clone --bare https://github.com/xiliumz/dotfiles.git "$HOME/.dotfiles"

# Make dot available in this shell
alias dot='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Check out dotfiles into $HOME
dot checkout

# Hide unrelated files
dot config --local status.showUntrackedFiles no

# Restore submodules
dot submodule update --init --recursive
```

The bare repository lives at:

```text
~/.dotfiles
```

while the actual tracked files are checked out directly into `$HOME`.

For example:

```text
~/.dotfiles/          # Git metadata
~/.bashrc             # tracked dotfile
~/.config/nvim/       # nvim submodule
```

---

### 🔄 Updating an Existing Machine

Pull the latest dotfiles and update submodules:

```bash
dot pull --recurse-submodules
dot submodule update --init --recursive
```
