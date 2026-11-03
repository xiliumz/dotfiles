{
  stdenvNoCC,
  fetchurl,
  lib,
}:
let
  version = "0.14.0";

  platforms = {
    "aarch64-darwin" = {
      arch = "aarch64-apple-darwin";
      sha256 = "0mclchzmdmymcfgn8f0swgzrnxrfjxyar11wlj2c1kb1zscfmqfi";
    };
    "aarch64-linux" = {
      arch = "aarch64-unknown-linux-musl";
      sha256 = "0rg23qqw6cs3ycldjjxisq5ja7r3v024zd06f3qpf3hyd0qgp085";
    };
    "x86_64-darwin" = {
      arch = "x86_64-apple-darwin";
      sha256 = "1z333cpg4ba2bvqrs60kpgq5rl1civli8ilrm9s0lc33fk93si4j";
    };
    "x86_64-linux" = {
      arch = "x86_64-unknown-linux-musl";
      sha256 = "1nfldsrnyx6yvzzpzd0jl1aqsv9wbq3ckw3dpal4qm2w5cfw5kzk";
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
