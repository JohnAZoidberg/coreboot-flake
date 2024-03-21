{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    gmp = {
      type = "tarball";
      url = "https://ftpmirror.gnu.org/gmp/gmp-6.3.0.tar.xz";
      flake = false;
      # name = "gmp-6.3.0.tar.xz";
    };
    mpfr = {
      type = "file";
      url = "https://ftpmirror.gnu.org/mpfr/mpfr-4.2.1.tar.xz";
      flake = false;
      # name = "mpfr-4.2.1.tar.xz";
    };
    mpc = {
      url = "file+https://ftpmirror.gnu.org/mpc/mpc-1.3.1.tar.gz";
      flake = false;
      # name = "mpc-1.3.1.tar.gz";
    };
    binutils = {
      url = "file+https://ftpmirror.gnu.org/binutils/binutils-2.42.tar.xz";
      flake = false;
      # name = "binutils-2.42.tar.xz";
    };
    gcc = {
      url = "file+https://ftpmirror.gnu.org/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz";
      flake = false;
      # name = "gcc-13.2.0.tar.xz";
    };
    coreboot = {
      url = "https://coreboot.org/releases/coreboot-24.02.01.tar.xz";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
      ];
      imports = [
        ./common/flake-module.nix
      ];
    };
}
