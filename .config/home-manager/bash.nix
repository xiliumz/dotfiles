{ pkgs, ... }:

{
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.bash = {
    enable = true;
    package = pkgs.bashInteractive;
    enableCompletion = true;

    historyControl = [ "ignoreboth" ];
    historySize = 1000;
    historyFileSize = 2000;
    shellOptions = [
      "histappend"
      "checkwinsize"
      "extglob"
      "globstar"
      "checkjobs"
    ];

    sessionVariables.GCC_COLORS = "error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";

    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      alert = ''notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history | tail -n1 | sed -e 's/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//')"'';

      dot = "git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
      dst = "dot status";
      dps = "dot push";
      dpl = "dot pull";
      da = "dot add";
      dcm = "dot commit -m";

      gst = "git status";
      gps = "git push";
      gpl = "git pull";
      ga = "git add";
      gf = "git fetch";
      gb = "git branch";

      cdnvim = "cd ~/.config/nvim";
      cdpi = "cd ~/.pi/agent/";
      t = "tmux";
      switch = "home-manager switch --flake ~/.config/home-manager#default";
    };

    profileExtra = ''
      if [ -d "$HOME/bin" ]; then
        PATH="$HOME/bin:$PATH"
      fi
      if [ -d "$HOME/.local/bin" ]; then
        PATH="$HOME/.local/bin:$PATH"
      fi
      if [ -f "$HOME/.local/bin/env" ]; then
        . "$HOME/.local/bin/env"
      fi
      if [ -d "$HOME/.nix-profile/bin" ]; then
        PATH="$HOME/.nix-profile/bin:$PATH"
      fi
    '';

    initExtra = ''
      if [ -x /usr/bin/lesspipe ]; then
        eval "$(SHELL=/bin/sh lesspipe)"
      fi

      if [ -z "''${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
        debian_chroot=$(cat /etc/debian_chroot)
      fi

      parse_git_branch() {
        git branch --show-current 2>/dev/null
      }

      git_status_hint() {
        git rev-parse --is-inside-work-tree &>/dev/null || return

        local ahead behind dirty status=""
        ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
        behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)
        git diff --quiet 2>/dev/null || dirty="*"

        [[ $ahead -gt 0 ]] && status+="↑"
        [[ $behind -gt 0 ]] && status+="↓"
        [[ -n $dirty ]] && status+="$dirty"

        echo "$status"
      }

      if [ -x /usr/bin/tput ] && tput setaf 1 &>/dev/null; then
        PS1='\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(branch=$(parse_git_branch); if [ -n "$branch" ]; then hint=$(git_status_hint); echo " \[\033[1;38;5;208m\]($branch$hint)\[\033[00m\]"; fi)\n\$ '
      else
        PS1='\u:\w$(branch=$(parse_git_branch); if [ -n "$branch" ]; then hint=$(git_status_hint); echo " ($branch$hint)"; fi)\n\$ '
      fi

      case "$TERM" in
        xterm*|rxvt*)
          PS1="\[\e]0;''${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
          ;;
      esac

      if [ -x /usr/bin/dircolors ]; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
        alias ls='ls --color=auto'
        alias dir='dir --color=auto'
        alias vdir='vdir --color=auto'
        alias grep='grep --color=auto'
        alias fgrep='fgrep --color=auto'
        alias egrep='egrep --color=auto'
      fi

      # Source this at runtime: it contains private settings, not Nix-store data.
      if [ -f "$HOME/.bash_aliases" ]; then
        . "$HOME/.bash_aliases"
      fi

      if ! command -v nix >/dev/null 2>&1; then
        echo "Nix is not installed. Install Nix before applying this setup."
      elif ! command -v home-manager >/dev/null 2>&1; then
        echo "Home Manager is not installed. Run the Home Manager bootstrap."
      fi

      if [ -f /usr/share/bash-completion/completions/git ]; then
        source /usr/share/bash-completion/completions/git
        __git_complete dot __git_main
      fi

      develop() {
        nix develop "path:''${1:-.}"
      }
    '';
  };
}
