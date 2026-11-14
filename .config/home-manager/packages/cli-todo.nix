{
  stdenvNoCC,
  fetchurl,
  lib,
}:
let
  version = "0.26.0";

  platforms = {
    "aarch64-darwin" = {
      arch = "aarch64-apple-darwin";
      sha256 = "19bjgjhpffw91pyhyawipai21vl20lcf6d7hkfrk21n702x2ca2b";
    };
    "aarch64-linux" = {
      arch = "aarch64-unknown-linux-musl";
      sha256 = "0r4xfjg8q4lknrj9q7g3d21q90vq1b28md9hkwr848705p86g4xs";
    };
    "x86_64-darwin" = {
      arch = "x86_64-apple-darwin";
      sha256 = "073n3l2qpgvwlvxsm5bs5yca4k42rv3q9l7aqw5rx2l4dx5r1awg";
    };
    "x86_64-linux" = {
      arch = "x86_64-unknown-linux-musl";
      sha256 = "164iyrv535546i2giv53vil8g553mfgv1sbkrakxpkxcv9gbj5ax";
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
