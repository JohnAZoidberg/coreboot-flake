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
          coreboot_version = "24.05";
          tianocore_tag = "edk2-stable202402";
          mrchromebox_branch = "uefipayload_202304";

          coreboot_tarball = pkgs.fetchurl {
            url = "https://coreboot.org/releases/coreboot-${coreboot_version}.tar.xz";
            hash =
              {
                "24.02" = "sha256-dBZYK2b/NZq/Y9qb5cTRmeQoBQZukZfe8vDDjcfEcq4=";
                "24.02.01" = "sha256-5W9cDJAIv97BxL5kCawJNoAUD5RB79PV5Hve/8v3flA=";
                "24.05" = "sha256-4ir9usQAaLpof9l18D9rlYWZoy5w9TnZ0MdNFqY9fOo=";
              }
              .${coreboot_version};
          };

          coreboot_blobs_tarball = pkgs.fetchurl {
            url = "https://coreboot.org/releases/coreboot-blobs-${coreboot_version}.tar.xz";
            hash =
              {
                "24.02" = "sha256-Uck3a74vnSlDlgfVUjkipuKAH7d8Z69GmQCfks/+3/0=";
                "24.02.01" = "sha256-jQO4LNKyWTRz1M1RHHvvf91Dg5I39sN6g4MWFmDBRCc=";
                "24.05" = "sha256-0jaBacub79EPmv/pv3Zj5v84uArldyUV8I1LRyUKOoM=";
              }
              .${coreboot_version};
          };

          edk2-MrChromebox = pkgs.fetchgit (
            {
              url = "https://github.com/MrChromebox/edk2";
              fetchSubmodules = true;
            }
            // {
              "uefipayload_202304" = {
                rev = "cbf33b54e18c5e48d1b4030f0b7e307f56d65a76";
                hash = "sha256-fsrhlF8Bdak8kVJjCcbA2PgJOsxdTvaXu/xp391pgr0=";
              };
              "uefipayload_202306" = {
                rev = "92533b23fb93259b20661b6534109e9f59384e93";
                hash = "sha256-R+SDEDgF81utfLqk28SmLepWDmuwUjyY3gLLLhT7LBM=";
              };
              "uefipayload_202309" = {
                rev = "b984bd77f3dc523394bb3bbc834d421e2761dfee";
                hash = "sha256-ewCMOKuahTa4qGTuXhlfBm2P3snYe9iEQngAGwMQ2VI=";
              };
              "uefipayload_2402" = {
                rev = "7f398d3b14928ffecbbe92bd93213db91dad7703";
                hash = "sha256-USAhJ0Y9TU6cFlrKL9pjH5sVujsNNHb4lmDQ5ekQEsg=";
              };
              "uefipayload_2405" = {
                rev = "b984bd77f3dc523394bb3bbc834d421e2761dfef";
                hash = "sha256-rTaCD1QUq7XmHu0qFtErlDZg4csFzqdfjv2e0gOBgA4=";
              };
              "uefipayload_2408" = {
                rev = "78c2b10586e58b23920ec0f4d3cc1cf5fdd0b979";
                hash = "sha256-4sjEA96K9Fu8tdSCIHlCIZY05LwdJZyS7JzAyXO9fYI=";
              };
            }
            .${mrchromebox_branch}
          );

          edk2-tianocore = pkgs.fetchgit {
            url = "https://github.com/tianocore/edk2";
            rev = "refs/tags/${tianocore_tag}";
            fetchSubmodules = true;
            hash =
              {
                "edk2-stable202305" = "";
                "edk2-stable202308" = "sha256-Eoi1xf/hw/Knr7n0f0rgVof7wTgrHkmvV4eJjJV1NhM=";
                "edk2-stable202311" = "sha256-k2synazhln95a3YBqB3Gtfx3y6ThCtvNuF8wvaTS1Mo=";
                "edk2-stable202402" = "sha256-Nurm6QNKCyV6wvbj0ELdYAL7mbZ0yg/tTwnEJ+N18ng=";
                "edk2-stable202405" = "sha256-UvoTMBUSYjs7blNeRUEoheTdmpMyu2n3W6QAEdy6GQc=";
              }
              .${tianocore_tag};
          };

          edk2-platforms = pkgs.fetchgit {
            url = "https://github.com/tianocore/edk2-platforms";
            rev = "debfeb1f3052ca4d9cc386b9e8aaada5f7da4c60";
            hash = "sha256-ksTDBqoKvod/tmLPmV9Zj0Ed4JPnVerujYF3wG/2MpQ=";
          };
        in
        {
          coreboot-vp4670 = pkgs.stdenv.mkDerivation {
            pname = "coreboot-vp4670";
            version = coreboot_version;

            srcs = [
              coreboot_tarball
              coreboot_blobs_tarball
            ];

            nativeBuildInputs = [
              pkgs.coreboot-toolchain.i386
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
              pkgs.ncurses.dev
            ];

            env = {
              BUILD_TIMELESS = 1;

              # coreboot source describes this as "misleadingly named, this is
              # the coreboot version".  We set this to $out, so that you can
              # always find the outpath a machine's current bootflash image by
              # simply reading the image back (`flashrom -r`) and running
              # `strings | grep /nix/store` on the result.
              KERNELVERSION = builtins.placeholder "out";
            };

            # enableParallelBuilding = true;

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

              mkdir -p payloads/external/edk2/workspace

              cp -r ${edk2-platforms} payloads/external/edk2/workspace/edk2-platforms

              cp -r ${edk2-tianocore} payloads/external/edk2/workspace/tianocore
              chmod -R +w   payloads/external/edk2/workspace/tianocore/
              patchShebangs payloads/external/edk2/workspace/tianocore/BaseTools/BinWrappers/PosixLike/TianoCompress
              patchShebangs payloads/external/edk2/workspace/tianocore/BaseTools/BinWrappers/PosixLike/build

              cp -r ${edk2-MrChromebox} payloads/external/edk2/workspace/mrchromebox
              chmod -R +w   payloads/external/edk2/workspace/mrchromebox/
              patchShebangs payloads/external/edk2/workspace/mrchromebox/BaseTools/BinWrappers/PosixLike/TianoCompress
              patchShebangs payloads/external/edk2/workspace/mrchromebox/BaseTools/BinWrappers/PosixLike/build
            '';

            installPhase = ''
              mkdir -p $out
              install -m 0444 build/coreboot.rom $out
            '';
          };
        };
    };
}
