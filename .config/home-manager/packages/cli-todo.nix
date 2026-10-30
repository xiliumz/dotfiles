{
  stdenvNoCC,
  fetchurl,
  lib,
}:
let
  version = "0.11.1";

  platforms = {
    "aarch64-darwin" = {
      arch = "aarch64-apple-darwin";
      sha256 = "0qg0lghlagf1cn6lmilaj70xbi1k8ky12p9h0bk2npvsjdnxrcsw";
    };
    "aarch64-linux" = {
      arch = "aarch64-unknown-linux-musl";
      sha256 = "06hwb77bq17w1ljnragixjsq3id55xm8wsxlvjdwrhl33x65v84b";
    };
    "x86_64-darwin" = {
      arch = "x86_64-apple-darwin";
      sha256 = "0glvcs50i5nfapr319nc3vgwfwkjw88nm716d9lh7i8gy426n9cr";
    };
    "x86_64-linux" = {
      arch = "x86_64-unknown-linux-musl";
      sha256 = "0jd63sb3sc10dl62qngizlddaf4gs8bpcvy3ns3md49zxfimm1hp";
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
