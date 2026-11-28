{ config, pkgs, ... }:

# Rootless Docker without a systemd user session.
# Docker itself (dockerd-rootless.sh, docker-ce-rootless-extras) comes from apt.
# Each user still needs /etc/subuid and /etc/subgid entries (admin, once).
let
  runDir = "${config.home.homeDirectory}/.docker/run";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "docker-rootless-start" ''
      export XDG_RUNTIME_DIR=${runDir}
      export DOCKER_HOST=unix://${runDir}/docker.sock
      mkdir -p "$XDG_RUNTIME_DIR"
      if /usr/bin/docker info >/dev/null 2>&1; then echo "already running"; exit 0; fi
      PATH=/usr/bin:/sbin:/usr/sbin:$PATH setsid nohup /usr/bin/dockerd-rootless.sh \
        >/tmp/dockerd-rootless-$(id -u).log 2>&1 </dev/null &
      for _ in $(seq 20); do
        /usr/bin/docker info >/dev/null 2>&1 && { echo "started"; exit 0; }
        sleep 1
      done
      echo "failed, see /tmp/dockerd-rootless-$(id -u).log"
      exit 1
    '')
  ];

  # Without a systemd user session, the systemd cgroup driver breaks every container.
  xdg.configFile."docker/daemon.json".text = builtins.toJSON {
    exec-opts = [ "native.cgroupdriver=cgroupfs" ];
  };

  # Rootless Docker socket, for tools that ignore `docker context`.
  home.sessionVariables.DOCKER_HOST = "unix://${runDir}/docker.sock";
}
