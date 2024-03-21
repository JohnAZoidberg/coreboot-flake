{inputs, ...}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
in {
  flake.packages.x86_64-linux = rec {
    corebootEnv = pkgs.buildFHSUserEnv {
      name = "coreboot-env";
      targetPkgs = pkgs:
        with pkgs; [
          binutils
          gnat
          gnumake
          coreutils
          patch
          zlib
          zlib.dev
          curl
          git
          m4
          bison
          flex
        ];
    };
    corebootToolchain = pkgs.stdenv.mkDerivation {
      pname = "coreboot-toolchain";
      version = "24.02.01";

      src = inputs.coreboot;

      # Because the binaries that are build in the chroot reference
      # shared libraries in a way that will not work outside of it, we
      # need to patch the resulting ELFs.
      #
      # This is conceptually similar to how externally-built binary
      # packages, such as Steam or MS Teams, are built. autoPatchelfHook
      # is taking care of the heavy lifting here.
      #
      # There is small wrinkle here: autoPatchelfHook assumes it has a
      # working compilation environment with binutils. That's why we use
      # `mkDerivation` instead of `mkDerivationNoCC` for the toolchain
      # derivation.
      nativeBuildInputs = [corebootEnv pkgs.autoPatchelfHook];
      buildInputs = [pkgs.zlib pkgs.flex pkgs.gcc.cc.lib];

      postPatch = ''
        echo "DIBUX ${inputs.gmp}"
        ls -l ${inputs.gmp}
        mkdir -p util/crossgcc/tarballs
        ln -s ${inputs.gmp} util/crossgcc/tarballs/
        ln -s ${inputs.mpfr} util/crossgcc/tarballs/
        ln -s ${inputs.mpc} util/crossgcc/tarballs/
        ln -s ${inputs.binutils} util/crossgcc/tarballs/
        ln -s ${inputs.gcc} util/crossgcc/tarballs/
        echo "cur dir:"
        ls -l .
        echo "util/:"
        ls -l util/
        echo "util/crosgcc/:"
        ls -l util/crosgcc/
        echo "util/crosgcc/tarballs/ :"
        ls -l util/crosgcc/tarballs/
      '';

      buildPhase = let
        buildScript = pkgs.writeText "coreboot-toolchain-build" ''
          export PATH=/bin:/sbin:/usr/bin:/usr/sbin

          mkdir -p $out
          make crossgcc-i386 CPUS=$(nproc) DEST=$out
        '';
      in ''
        coreboot-env ${buildScript}
      '';

      installPhase = ''
        echo Already installed.
      '';
    };
    default = corebootToolchain;
  };
}
