{
  stdenvNoCC,
  fetchurl,
  lib,
}:
let
  version = "0.8.0";

  platforms = {
    "aarch64-darwin" = {
      arch = "aarch64-apple-darwin";
      sha256 = "0y8ggqqrvjh10ibb2pwfiasp2c7q08a4p4ylc806wfcrc4fbf3ik";
    };
    "aarch64-linux" = {
      arch = "aarch64-unknown-linux-musl";
      sha256 = "1ksfg05nk3lp60qcgrpn2lbqlngc96kf6i6qas264wkr9p38xgk8";
    };
    "x86_64-darwin" = {
      arch = "x86_64-apple-darwin";
      sha256 = "1jk9avrkgmv4dhjchjq0yhsr9kp3ffc99mh2i6z1xam9gq2zy1kw";
    };
    "x86_64-linux" = {
      arch = "x86_64-unknown-linux-musl";
      sha256 = "1b28290zdmf1sxcxbc9j8yvw0vmmawj5mbd6p80cmi0g92ymq9ks";
    };
  };
  platform = platforms.${stdenvNoCC.hostPlatform.system} or (throw "unsupported system");
in

stdenvNoCC.mkDerivation {
  pname = "cli-todo";
  inherit version;

  src = fetchurl {
    url = "https://github.com/The-Terrans/cli-todo/releases/download/${version}/cli-todo-${version}-${platform.arch}.tar.gz";
    inherit (platform) sha256;
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    chmod +x $out/bin/cli-todo
  '';

  meta = with lib; {
    description = "A simple todo CLI";
    homepage = "https://github.com/The-Terrans/cli-todo";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
