### 🧠 Concept

Normally, when you run `git init`, Git creates a `.git` folder **inside** the current directory to store all versioning data.

But in this setup, we tell Git to:

* Store its **metadata** in `~/.dotfiles`
* Treat your **home directory (`~`)** as the **working tree**

So your files like `~/.bashrc`, `~/.zshrc`, and `~/.config/nvim/init.lua` stay in their usual places — **no duplication, no clutter** — but Git tracks them using the hidden `.dotfiles` repo.

---

### 🧰 Setup Recap

Here’s the minimal setup again:

```bash
# 1. Create a bare repo to store version control info
git init --bare $HOME/.dotfiles

# 2. Create a convenient alias for using this repo
echo "alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'" >> ~/.bashrc
source ~/.bashrc  # or ~/.zshrc
```

Now you can use the alias `dotfiles` like a normal git command:

```bash
dotfiles status
dotfiles add .bashrc .zshrc .config/nvim
dotfiles commit -m "Initial commit"
dotfiles remote add origin git@github.com:yourusername/dotfiles.git
dotfiles push -u origin main
```

---

### 💡 Important Step

Hide untracked files from your whole home directory (otherwise Git will list everything in your home):

```bash
dotfiles config --local status.showUntrackedFiles no
```

---

### 📦 On a New Machine

You can restore your setup by doing:

```bash
git clone --bare git@github.com:yourusername/dotfiles.git $HOME/.dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no
```

