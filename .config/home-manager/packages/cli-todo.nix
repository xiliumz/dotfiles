{
  stdenvNoCC,
  fetchurl,
  lib,
}:
let
  version = "0.5.0";

  platforms = {
    "x86_64-linux" = {
      arch = "x86_64-unknown-linux-musl";
      sha256 = "1cgb1svk99zz3fhrxbhnwdc5p5ypj50fvg4cdmp0m562pkw99ap5";
    };
    "aarch64-linux" = {
      arch = "aarch64-unknown-linux-musl";
      sha256 = "0mq1l75w4j0gqbf7334nyxm6lsisavvas29gi1m5bih3a6kzh5qx";
    };
    "x86_64-darwin" = {
      arch = "x86_64-apple-darwin";
      sha256 = "1nw73b5cz1sgs69lsp6xbypiyd31fi0s2bx4ps3j3ks6nvlc685y";
    };
    "aarch64-darwin" = {
      arch = "aarch64-apple-darwin";
      sha256 = "179bkmx18xhicxaxq5gj9p55c6sm7z9s3c1kcda8mnzv7a8sasbz";
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
