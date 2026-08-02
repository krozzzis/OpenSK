{
  description = "OpenSK development environment (build + flash for nRF52840 boards)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        # Keep in sync with third_party/wasefire/rust-toolchain.toml (the toolchain file that
        # actually governs `cargo xtask`/`cargo wasefire` invocations, since that's where they
        # run from). It cannot be read directly from the flake because it lives in a git
        # submodule, which Nix's source filtering does not see.
        rustToolchain = pkgs.rust-bin.nightly."2026-06-03".default.override {
          extensions = [ "clippy" "llvm-tools" "rust-src" "rustfmt" ];
          targets = [
            "i686-unknown-linux-gnu"
            "riscv32imc-unknown-none-elf"
            "thumbv7em-none-eabi"
            "wasm32-unknown-unknown"
            "x86_64-unknown-linux-gnu"
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "opensk";

          nativeBuildInputs = [
            pkgs.pkg-config
          ];

          buildInputs = [
            rustToolchain
            pkgs.stdenv.cc

            pkgs.libusb1
            pkgs.openssl

            # Used to flash boards with a UF2 bootloader (e.g. nice!nano) and to generate the
            # development PKI (crypto_data/*).
            pkgs.python3
            pkgs.git
          ];

          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
      });
}
