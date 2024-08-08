{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, ... }@inputs:
    let
      pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
    in
    {
      formatter."x86_64-linux" = pkgs.nixfmt-rfc-style;
      packages."x86_64-linux" =
        let
          gmp_filename = "gmp-6.3.0.tar.xz";
          gmp_tarball = pkgs.fetchurl {
            url = "https://ftpmirror.gnu.org/gmp/${gmp_filename}";
            hash = "sha256-o8K4AgG4nmhhb0rTC8Zq7kknw85Q4zkpyoGdXENTiJg=";
          };
          mpfr_filename = "mpfr-4.2.1.tar.xz";
          mpfr_tarball = pkgs.fetchurl {
            url = "https://ftpmirror.gnu.org/mpfr/${mpfr_filename}";
            hash = "sha256-J3gHNTpnJpeJlpRa8T5Sgp46vXqaW3+yeTiU4Y8fy7I=";
          };
          mpc_filename = "mpc-1.3.1.tar.gz";
          mpc_tarball = pkgs.fetchurl {
            url = "https://ftpmirror.gnu.org/mpc/${mpc_filename}";
            hash = "sha256-q2QkkvXPiCt0qgy3MM1BCoHtzb7IlRg86TDnBsHHWbg=";
          };
          binutils_filename = "binutils-2.42.tar.xz";
          binutils_tarball = pkgs.fetchurl {
            url = "https://ftpmirror.gnu.org/binutils/${binutils_filename}";
            hash = "sha256-9uTUH9X8d4sGt4kUV7NiDaXs6hAGxqSkGumYEJ+FqAA=";
          };
          gcc_version = "13.2.0";
          gcc_filename = "gcc-${gcc_version}.tar.xz";
          gcc_tarball = pkgs.fetchurl {
            url = "https://ftpmirror.gnu.org/gcc/gcc-${gcc_version}/${gcc_filename}";
            hash = "sha256-4nXnZEKmBnNBon8Exca4PYYTFEAEwEE1KIY9xrXHQ9o=";
          };
          nasm_version = "2.16.01";
          nasm_filename = "nasm-${nasm_version}.tar.bz2";
          nasm_tarball = pkgs.fetchurl {
            url = "https://www.nasm.us/pub/nasm/releasebuilds/${nasm_version}/${nasm_filename}";
            hash = "sha256-NbatLuBI1BxHefBz8+/Kd2KoIrfS1O9OjfJM9ldHuy4=";
          };
          acpica_filename = "acpica-unix-20230628.tar.gz";
          acpica_tarball = pkgs.fetchurl {
            url = "https://downloadmirror.intel.com/783534/${acpica_filename}";
            hash = "sha256-hodqdF49Ik3P0iLtPeRltHVZ6FgR3y25gg7wmp3/XM4=";
          };
          coreboot_version = "24.05";
          coreboot_tarball = pkgs.fetchurl {
            url = "https://coreboot.org/releases/coreboot-${coreboot_version}.tar.xz";
            hash = "sha256-4ir9usQAaLpof9l18D9rlYWZoy5w9TnZ0MdNFqY9fOo=";
          };
        in

        rec {
          gnatWithCxx = pkgs.wrapCC (
            pkgs.gcc.cc.override {
              name = "gnat";
              langC = true;
              langCC = true;
              langAda = true;
              profiledCompiler = false;
              gnat-bootstrap = pkgs.gnat;
            }
          );

          corebootEnv = pkgs.buildFHSUserEnv {
            name = "coreboot-env";
            targetPkgs =
              pkgs: with pkgs; [
                gnatWithCxx
                binutils
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
                pkg-config
                ncurses
                ncurses.dev
                perl
                tree
              ];
          };
          corebootToolchain = pkgs.stdenv.mkDerivation {
            pname = "coreboot-toolchain";
            version = coreboot_version;

            src =
              let
                coreboot_version = "24.05";
              in
              pkgs.fetchurl {
                url = "https://coreboot.org/releases/coreboot-${coreboot_version}.tar.xz";
                hash = "sha256-4ir9usQAaLpof9l18D9rlYWZoy5w9TnZ0MdNFqY9fOo=";
              };

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
            nativeBuildInputs = [
              corebootEnv
              pkgs.autoPatchelfHook
            ];
            buildInputs = [
              pkgs.zlib
              pkgs.flex
              pkgs.gcc.cc.lib
            ];

            postPatch = ''
              mkdir -p util/crossgcc/tarballs
              ln -s ${gmp_tarball} util/crossgcc/tarballs/${gmp_filename}
              ln -s ${mpfr_tarball} util/crossgcc/tarballs/${mpfr_filename}
              ln -s ${mpc_tarball} util/crossgcc/tarballs/${mpc_filename}
              ln -s ${binutils_tarball} util/crossgcc/tarballs/${binutils_filename}
              ln -s ${gcc_tarball} util/crossgcc/tarballs/${gcc_filename}
              ln -s ${nasm_tarball} util/crossgcc/tarballs/${nasm_filename}
              ln -s ${acpica_tarball} util/crossgcc/tarballs/${acpica_filename}
            '';

            buildPhase =
              let
                buildScript = pkgs.writeText "coreboot-toolchain-build" ''
                  # export PATH=/bin:/sbin:/usr/bin:/usr/sbin
                  # mkdir -p util/crossgcc/build-GMP/
                  # make VERBOSE=1 crossgcc-i386 CPUS=$(nproc) DEST=$(pwd)/out-prefix
                  make crossgcc-i386 CPUS=$(nproc) DEST=$(pwd)/out-prefix
                '';
              in
              ''
                coreboot-env ${buildScript}
              '';

            installPhase = ''
              mkdir -p $out
              cp -r ./out-prefix/* $out/
            '';
          };
          # Finally, we can build coreboot itself. It's cross compilation
          # scripting (xcompile) will find its toolchain in PATH and use it to
          # build the target binaries. The normal Nix toolchain is used for
          # host binaries.
          #
          # The coreboot build is well-behaved, so there is no need to do it
          # in a chroot.
          coreboot = pkgs.stdenv.mkDerivation {
            pname = "coreboot";
            version = coreboot_version;

            src = coreboot_tarball;

            nativeBuildInputs = [ corebootToolchain ];

            postPatch = ''
              patchShebangs util/xcompile/xcompile
            '';

            buildPhase = ''
              cp ${./config} .config

              make olddefconfig
              make
            '';

            installPhase = ''
              prefix=$out/share/coreboot

              mkdir -p $prefix
              install -m 0444 build/coreboot.rom $prefix
            '';
          };
          default = coreboot;
        };
    };
}
