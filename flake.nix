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
          tianocore_tag = "edk2-stable202408";

          coreboot_tarball = pkgs.fetchurl {
            url = "https://coreboot.org/releases/coreboot-${coreboot_version}.tar.xz";
            hash =
              {
                "24.05" = "sha256-4ir9usQAaLpof9l18D9rlYWZoy5w9TnZ0MdNFqY9fOo=";
                "24.08" = "";
              }
              .${coreboot_version};
          };

          coreboot_blobs_tarball = pkgs.fetchurl {
            url = "https://coreboot.org/releases/coreboot-blobs-${coreboot_version}.tar.xz";
            hash =
              {
                "24.05" = "sha256-0jaBacub79EPmv/pv3Zj5v84uArldyUV8I1LRyUKOoM=";
                "24.08" = "";
              }
              .${coreboot_version};
          };

          edk2-tianocore = pkgs.fetchgit {
            url = "https://github.com/tianocore/edk2";
            rev = "refs/tags/${tianocore_tag}";
            fetchSubmodules = true;
            hash =
              {
                "edk2-stable202405" = "sha256-UvoTMBUSYjs7blNeRUEoheTdmpMyu2n3W6QAEdy6GQc=";
                "edk2-stable202408" = "sha256-2odaTqiAZD5xduT0dwIYWj3gY/aFPVsTFbblIsEhBiA=";
              }
              .${tianocore_tag};
          };

          edk2-platforms = pkgs.fetchgit {
            url = "https://github.com/tianocore/edk2-platforms";
            rev = "c400d971093f8a2e2e5d91c3600625a3db61c4e0";
            hash = "sha256-JNFLdxNVqi/cvANJvDayHPAMDOjjTdZeMYDBNM2qBLo=";
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

            depsHostHost = [
              pkgs.coreboot-toolchain.i386
              pkgs.binutils
              pkgs.pkg-config
              pkgs.nss
              pkgs.python3
              pkgs.openssl
              pkgs.git
              pkgs.libuuid.dev
              pkgs.libuuid.lib
              pkgs.libuuid
              pkgs.stduuid
              pkgs.libcrossguid
              pkgs.crossguid
              pkgs.imagemagick
              pkgs.cmake
              pkgs.ncurses
              pkgs.libossp_uuid
            ];

            depsBuildBuild = [
              pkgs.coreboot-toolchain.i386
              pkgs.binutils
              pkgs.pkg-config
              pkgs.nss
              pkgs.python3
              pkgs.openssl
              pkgs.git
              pkgs.libuuid.dev
              pkgs.libuuid.lib
              pkgs.libuuid
              pkgs.stduuid
              pkgs.libcrossguid
              pkgs.crossguid
              pkgs.imagemagick
              pkgs.cmake
              pkgs.ncurses
              pkgs.libossp_uuid
            ];

            makeFlags = [ "V=1" ];

            strictDeps = true;

            env = {
              BUILD_TIMELESS = 1;

              # coreboot source describes this as "misleadingly named, this is
              # the coreboot version".  We set this to $out, so that you can
              # always find the outpath a machine's current bootflash image by
              # simply reading the image back (`flashrom -r`) and running
              # `strings | grep /nix/store` on the result.
              KERNELVERSION = builtins.placeholder "out";
            };

            enableParallelBuilding = true;

            patches = [ ./0001-nix-fix.patch ];

            dontFixup = true;

            postPatch = ''
              patchShebangs util/xcompile/xcompile
              patchShebangs util/genbuild_h/genbuild_h.sh

              mkdir -p payloads/external/edk2/workspace

              cp -r ${edk2-platforms} payloads/external/edk2/workspace/edk2-platforms
              chmod -R +w             payloads/external/edk2/workspace/edk2-platforms

              cp -r ${edk2-tianocore} payloads/external/edk2/workspace/tianocore
              chmod -R +w             payloads/external/edk2/workspace/tianocore

              patchShebangs           payloads/external/edk2/workspace/tianocore/BaseTools/BinWrappers/PosixLike

              # https://github.com/tianocore/edk2/issues/6135
              substituteInPlace payloads/external/edk2/workspace/tianocore/UefiPayloadPkg/UefiPayloadPkg.dsc \
                  --replace-fail 'Build/UefiPayloadPkg$(BUILD_ARCH)' 'Build/UefiPayloadPkgX64'
            '';

            configurePhase = ''
              cp ${./vp4670/defconfig} ./.config
              cp -r ${./vp4670} ./vp4670
              make olddefconfig
            '';

            installPhase = ''
              mkdir -p $out
              install -m 0444 build/coreboot.rom $out
            '';
          };
        };
    };
}
