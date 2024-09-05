{
  inputs,
  version,
}:
{
  # board name, as in ./configs
  board,
  # normal callPackage attrs
  coreboot-toolchain,
  imagemagick,
  libuuid,
  ncurses,
  nss,
  pkg-config,
  pkgsBuildBuild,
  python3,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "coreboot-${board}";
  inherit version;

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
  ];

  strictDeps = true;

  enableParallelBuilding = true;

  patches = [ ./0001-nix-fix.patch ];

  postPatch = ''
    cp ${../../configs/${board}}/* ./

    cp -r ${inputs.intel-fsp}/*       ./3rdparty/fsp/
    cp -r ${inputs.intel-microcode}/* ./3rdparty/intel-microcode/

    patchShebangs util/xcompile/xcompile
    patchShebangs util/genbuild_h/genbuild_h.sh

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
    cp ${../../configs/${board}/defconfig} .config
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

  installPhase = ''
    runHook preInstall
    install -D -m 0644 --target-directory=$out build/coreboot.rom
    runHook postInstall
  '';
}
