{
  stdenvNoCC,
  fetchurl,
  lib,
}:
let
  version = "0.9.0";

  platforms = {
    "aarch64-darwin" = {
      arch = "aarch64-apple-darwin";
      sha256 = "183picv7y479va7in0rycywrkk2akwa9spz4k4h21zj7f700n57y";
    };
    "aarch64-linux" = {
      arch = "aarch64-unknown-linux-musl";
      sha256 = "1jgjzbsd39kbfh00yhwxpm4bb90i4xwgq578qchw30i2lkgh14gr";
    };
    "x86_64-darwin" = {
      arch = "x86_64-apple-darwin";
      sha256 = "0inq376qrny4qmr4yngxf782znym70cnrxqnwdnmx8bw563663sv";
    };
    "x86_64-linux" = {
      arch = "x86_64-unknown-linux-musl";
      sha256 = "05y7f1z47139bimlz7y7mjrjj4z047l543yyilcmb8i6187qk2wb";
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
