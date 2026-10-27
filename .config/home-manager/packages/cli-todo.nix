{
  stdenvNoCC,
  fetchurl,
  lib,
}:
let
  version = "0.6.0";

  platforms = {
    "aarch64-darwin" = {
      arch = "aarch64-apple-darwin";
      sha256 = "1nvbzvfm40hbzcxrmfyj2kh4i86jxxlc237kd7vf1kjw948mqhwq";
    };
    "aarch64-linux" = {
      arch = "aarch64-unknown-linux-musl";
      sha256 = "0s9521kr2plfx7xk5nzqsk11yy9i7m08iwbbxzc8lq59lihi328j";
    };
    "x86_64-darwin" = {
      arch = "x86_64-apple-darwin";
      sha256 = "1vwcwg4jjvq09s02gv7z0g5r469wq2ssfacq4sr8m4f4cxbrw85b";
    };
    "x86_64-linux" = {
      arch = "x86_64-unknown-linux-musl";
      sha256 = "06b9g4ygfd0k5wcw964m87r9ayvpdiqdxrnxg511p8xb73wr6fpm";
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
