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
          coreboot_version = "24.08";
          coreboot_blobs_version = "24.05";

          coreboot_tarball = pkgs.fetchFromGitHub {
            owner = "coreboot";
            repo = "coreboot";
            rev = coreboot_version;
            fetchSubmodules = true;
            hash =
              {
                "24.05" = "sha256-Fq3tZje6QoMskxqWd61OstgI9Sj25yijf8S3LiTJuYc=";
                "24.08" = "sha256-BwuoBuWKHTnSwV8ubm5NqcddgxP5OMXuTl3zmwwKEsg=";
              }
              .${coreboot_version};
          };

          coreboot_blobs_tarball = pkgs.fetchurl {
            url = "https://coreboot.org/releases/coreboot-blobs-${coreboot_blobs_version}.tar.xz";
            hash =
              {
                "24.05" = "sha256-0jaBacub79EPmv/pv3Zj5v84uArldyUV8I1LRyUKOoM=";
                "24.08" = "";
              }
              .${coreboot_blobs_version};
          };

          edk2-tianocore = pkgs.fetchFromGitHub {
            owner = "tianocore";
            repo = "edk2";
            rev = "edk2-stable202408";
            hash = "sha256-2odaTqiAZD5xduT0dwIYWj3gY/aFPVsTFbblIsEhBiA=";
            fetchSubmodules = true;
          };

          edk2-MrChromebox = pkgs.fetchFromGitHub {
            owner = "MrChromebox";
            repo = "edk2";
            rev = "78c2b10586e58b23920ec0f4d3cc1cf5fdd0b979"; # "uefipayload_2408"
            hash = "sha256-4sjEA96K9Fu8tdSCIHlCIZY05LwdJZyS7JzAyXO9fYI=";
            fetchSubmodules = true;
          };

          edk2-platforms = pkgs.fetchFromGitHub {
            owner = "tianocore";
            repo = "edk2-platforms";
            rev = "c400d971093f8a2e2e5d91c3600625a3db61c4e0";
            hash = "sha256-fsyydk1Rov/srptEV8gIqj+w+6Eb2iiGiU2U0NQBMxU=";
          };

          coreboot-package =
            config:
            pkgs.stdenv.mkDerivation {
              pname = "coreboot-${config}";
              version = coreboot_version;

              src = coreboot_tarball;

              postUnpack = ''
                tar xf ${coreboot_blobs_tarball}
                cp -r coreboot-${coreboot_blobs_version}/* source/
                rm -rf coreboot-${coreboot_blobs_version}
              '';

              depsHostHost = [ pkgs.libuuid ];

              depsBuildBuild = [
                pkgs.coreboot-toolchain.i386
                pkgs.python3
                pkgs.imagemagick
                pkgs.nss
                pkgs.pkg-config
                # for 'make nconfig'
                pkgs.ncurses
              ];

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

              hardeningDisable = [ "all" ];

              patches = [ ./0001-nix-fix.patch ];

              makeFlags = [ "V=1" ];

              dontFixup = true;

              postPatch = ''
                patchShebangs util/xcompile/xcompile
                patchShebangs util/genbuild_h/genbuild_h.sh

                mkdir -p payloads/external/edk2/workspace

                cp -r ${edk2-platforms} payloads/external/edk2/workspace/edk2-platforms
                chmod -R +w             payloads/external/edk2/workspace/edk2-platforms

                cp -r ${edk2-tianocore} payloads/external/edk2/workspace/tianocore
                chmod -R +w             payloads/external/edk2/workspace/tianocore

                patchShebangs payloads/external/edk2/workspace/tianocore/BaseTools/BinWrappers/PosixLike

                # https://github.com/tianocore/edk2/issues/6135
                substituteInPlace payloads/external/edk2/workspace/tianocore/UefiPayloadPkg/UefiPayloadPkg.dsc \
                    --replace-fail 'Build/UefiPayloadPkg$(BUILD_ARCH)' 'Build/UefiPayloadPkgX64'

                cp -r ${edk2-MrChromebox} payloads/external/edk2/workspace/MrChromebox
                chmod -R +w               payloads/external/edk2/workspace/MrChromebox

                patchShebangs payloads/external/edk2/workspace/MrChromebox/BaseTools/BinWrappers/PosixLike

                # https://github.com/tianocore/edk2/issues/6135
                substituteInPlace payloads/external/edk2/workspace/MrChromebox/UefiPayloadPkg/UefiPayloadPkg.dsc \
                    --replace-fail 'Build/UefiPayloadPkg$(BUILD_ARCH)' 'Build/UefiPayloadPkgX64'
              '';

              configurePhase = ''
                cp -r ${./configs/${config}}/* ./
                mv defconfig .config
                make olddefconfig
              '';

              installPhase = ''
                mkdir -p $out
                install -m 0444 build/coreboot.rom $out/coreboot-${config}.rom
              '';
            };
        in
        {
          coreboot-vp4670 = coreboot-package "vp4670";
        };
    };
}
