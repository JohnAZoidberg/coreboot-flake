{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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
          coreboot_blobs_tarball = pkgs.fetchurl {
            url = "https://coreboot.org/releases/coreboot-blobs-${coreboot_version}.tar.xz";
            hash = "sha256-0jaBacub79EPmv/pv3Zj5v84uArldyUV8I1LRyUKOoM=";
          };
          edk2 = pkgs.fetchgit {
            url = "https://github.com/tianocore/edk2";
            rev = "refs/tags/edk2-stable202402";
            hash = "sha256-2iNCs1WhYy7MBTmEezozoC2lFg7FPvQe9eZ08HadP2E=";
            leaveDotGit = true;
            fetchSubmodules = true;
          };
          edk2-platforms = pkgs.fetchgit {
            url = "https://github.com/tianocore/edk2-platforms";
            rev = "debfeb1f3052ca4d9cc386b9e8aaada5f7da4c60";
            hash = "sha256-ksTDBqoKvod/tmLPmV9Zj0Ed4JPnVerujYF3wG/2MpQ=";
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
                # gnatWithCxx
                gnat
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
                libuuid
                libuuid.dev
                perl
                tree
              ];
          };

          corebootToolchain = pkgs.stdenv.mkDerivation {
            pname = "coreboot-toolchain";
            version = coreboot_version;

            src = coreboot_tarball;

            nativeBuildInputs = [
              corebootEnv
              pkgs.autoPatchelfHook
              pkgs.libuuid.dev
            ];

            buildInputs = [
              pkgs.zlib
              pkgs.libuuid
              pkgs.flex
              pkgs.gcc.cc.lib
            ];

            prePatch = ''
              mkdir -p util/crossgcc/tarballs
              ln -s ${gmp_tarball}      util/crossgcc/tarballs/${gmp_filename}
              ln -s ${mpfr_tarball}     util/crossgcc/tarballs/${mpfr_filename}
              ln -s ${mpc_tarball}      util/crossgcc/tarballs/${mpc_filename}
              ln -s ${binutils_tarball} util/crossgcc/tarballs/${binutils_filename}
              ln -s ${gcc_tarball}      util/crossgcc/tarballs/${gcc_filename}
              ln -s ${nasm_tarball}     util/crossgcc/tarballs/${nasm_filename}
              ln -s ${acpica_tarball}   util/crossgcc/tarballs/${acpica_filename}
            '';

            buildPhase =
              let
                buildScript = pkgs.writeShellScript "coreboot-toolchain-build" ''
                  make \
                      crossgcc-i386 \
                      CPUS=$(nproc) \
                      DEST=$(pwd)/out-prefix
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

          coreboot = pkgs.stdenv.mkDerivation {
            pname = "coreboot";
            version = coreboot_version;

            srcs = [
              coreboot_tarball
              coreboot_blobs_tarball
            ];

            nativeBuildInputs = [
              corebootToolchain
              pkgs.binutils
              pkgs.pkg-config
              pkgs.nss
              pkgs.python3
              pkgs.openssl.dev
              pkgs.git
              pkgs.libuuid
              pkgs.libuuid.dev
              pkgs.imagemagick
              pkgs.cmake
            ];

            enableParallelBuilding = true;

            patches = [ ./0001-nix-fix.patch ];

            postPatch = ''
              patchShebangs util/xcompile/xcompile
              patchShebangs util/genbuild_h/genbuild_h.sh
            '';

            configurePhase = ''
              cp ${./vp4670/defconfig} ./.config
              make olddefconfig
            '';

            preBuild = ''
              cp -r ${./vp4670} ./vp4670

              mkdir -p                payloads/external/edk2/workspace
              cp -r ${edk2}           payloads/external/edk2/workspace/tianocore
              cp -r ${edk2-platforms} payloads/external/edk2/workspace/edk2-platforms

              chmod -R +w payloads/external/edk2/workspace/tianocore/

              patchShebangs payloads/external/edk2/workspace/tianocore/BaseTools/BinWrappers/PosixLike/TianoCompress
              patchShebangs payloads/external/edk2/workspace/tianocore/BaseTools/BinWrappers/PosixLike/build
            '';

            installPhase = ''
              mkdir -p $out
              install -m 0444 build/coreboot.rom $out
            '';
          };

          default = coreboot;
        };
    };
}
