{ inputs, ... }:
{
  mkCorebootEdk2 =
    {
      board,
      # Boards whose SoC selects USE_X86_64_SUPPORT build their stages with the
      # x86_64-elf toolchain instead of (or in addition to) i386-elf.
      x86_64 ? false,
      # Boards with VBOOT enabled build futility, which links against libcrypto
      # (util/futility/Makefile.mk refuses to build without it).
      vboot ? false,
    }:
    {
      coreboot-toolchain,
      imagemagick,
      lib,
      libuuid,
      ncurses,
      nss,
      openssl,
      pkg-config,
      pkgsBuildBuild,
      python3,
      stdenvNoCC,
      ...
    }:
    stdenvNoCC.mkDerivation {
      pname = "coreboot-${board}";
      version = inputs.coreboot.shortRev;

      src = inputs.coreboot;

      depsBuildBuild = [
        pkgsBuildBuild.stdenv.cc
        coreboot-toolchain.i386
        imagemagick
        libuuid
        ncurses
        nss
        pkg-config
        python3
      ]
      ++ lib.optional x86_64 coreboot-toolchain.x64
      ++ lib.optional vboot openssl;

      strictDeps = true;

      enableParallelBuilding = true;

      patches =
        [
          ./0001-payloads-edk2-skip-git-script.patch
        ]
        ++ (
          let
            boardPatchesDir = ../packages/${board}/patches;
            boardPatches = lib.pipe boardPatchesDir [
              builtins.readDir
              builtins.attrNames
              (builtins.map (patchName: /${boardPatchesDir}/${patchName}))
            ];
          in
          if (builtins.pathExists boardPatchesDir) then boardPatches else [ ]
        );

      postPatch = ''
        cp -r ${../packages/${board}}/* ./

        cp -r ${inputs.intel-fsp}/*       ./3rdparty/fsp/
        cp -r ${inputs.intel-microcode}/* ./3rdparty/intel-microcode/

        patchShebangs util/xcompile/xcompile
        patchShebangs util/genbuild_h/genbuild_h.sh
        patchShebangs util/me_cleaner/me_cleaner.py
        ${lib.optionalString vboot "patchShebangs 3rdparty/vboot/scripts"}

        mkdir -p payloads/external/edk2/workspace

        cp -r ${inputs.edk2-platforms} payloads/external/edk2/workspace/edk2-platforms
        chmod -R +w                    payloads/external/edk2/workspace/edk2-platforms

        cp -r ${inputs.edk2-mrchromebox} payloads/external/edk2/workspace/MrChromebox
        chmod -R +w                      payloads/external/edk2/workspace/MrChromebox

        patchShebangs payloads/external/edk2/workspace/MrChromebox/BaseTools/BinWrappers/PosixLike

        # https://github.com/tianocore/edk2/issues/6135
        substituteInPlace payloads/external/edk2/workspace/MrChromebox/UefiPayloadPkg/UefiPayloadPkg.dsc \
            --replace-fail 'Build/UefiPayloadPkg$(BUILD_ARCH)' 'Build/UefiPayloadPkgX64'
      '';

      configurePhase = ''
        runHook preConfigure
        cp defconfig .config
        make -j$NIX_BUILD_CORES olddefconfig
        runHook postConfigure
      '';

      makeFlags = [
        "BUILD_TIMELESS=1"
        # coreboot source describes this as "misleadingly named, this is
        # the coreboot version".  We set this to $out, so that you can
        # always find the outpath a machine's current bootflash image by
        # simply reading the image back (`flashrom -r`) and running
        # `strings | grep /nix/store` on the result.
        "KERNELVERSION=${builtins.placeholder "out"}"
      ];

      postBuild =
        let
          cbfsDir = ../packages/${board}/cbfs;
          cbfsAddFileScript = cbfsFile: ''
            ./build/cbfstool build/coreboot.rom add -n ${cbfsFile} -t raw -f ${/${cbfsDir}/${cbfsFile}}
          '';
          cbfsScript = lib.pipe cbfsDir [
            builtins.readDir
            builtins.attrNames
            (builtins.map cbfsAddFileScript)
            lib.strings.concatStrings
          ];
        in
        if (builtins.pathExists cbfsDir) then cbfsScript else [ ];

      installPhase = ''
        runHook preInstall
        install -D -m 0644 --target-directory=$out build/coreboot.rom .config
        runHook postInstall
      '';
    };
}
