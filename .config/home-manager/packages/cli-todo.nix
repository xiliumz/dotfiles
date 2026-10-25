{
  stdenvNoCC,
  fetchurl,
  lib,
}:
let
  version = "0.5.0";

  arch =
    {
      "x86_64-linux" = "x86_64-unknown-linux-musl";
      "aarch64-linux" = "aarch64-unknown-linux-musl";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    }
    .${stdenvNoCC.hostPlatform.system} or (throw "unsupported system");

  hashes = {
    "x86_64-unknown-linux-musl" = "1cgb1svk99zz3fhrxbhnwdc5p5ypj50fvg4cdmp0m562pkw99ap5";
    "aarch64-unknown-linux-musl" = "0mq1l75w4j0gqbf7334nyxm6lsisavvas29gi1m5bih3a6kzh5qx";
    "x86_64-apple-darwin" = "1nw73b5cz1sgs69lsp6xbypiyd31fi0s2bx4ps3j3ks6nvlc685y";
    "aarch64-apple-darwin" = "179bkmx18xhicxaxq5gj9p55c6sm7z9s3c1kcda8mnzv7a8sasbz";
  };
in
stdenvNoCC.mkDerivation {
  pname = "cli-todo";
  inherit version;

  src = fetchurl {
    url = "https://github.com/The-Terrans/cli-todo/releases/download/${version}/cli-todo-${version}-${arch}.tar.gz";
    sha256 = hashes.${arch};
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
