{
  inputs = {
    coreboot = {
      url = "git+https://review.coreboot.org/coreboot.git?ref=refs/heads/main&submodules=1";
      flake = false;
    };
    edk2-platforms = {
      url = "github:tianocore/edk2-platforms";
      flake = false;
    };
    edk2-mrchromebox = {
      url = "git+https://github.com/MrChromebox/edk2?ref=refs/heads/uefipayload_2408&submodules=1";
      flake = false;
    };
    intel-microcode = {
      url = "github:intel/Intel-Linux-Processor-Microcode-Data-Files";
      flake = false;
    };
    intel-fsp = {
      url = "github:intel/FSP";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs?ref=refs/heads/nixpkgs-unstable";
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
    in
    {
      formatter.${system} = pkgs.nixfmt-rfc-style;
      packages.${system} = {
        vp4670 = pkgs.callPackage ./coreboot {
          board = "vp4670";
          inherit (inputs)
            coreboot
            edk2-platforms
            edk2-mrchromebox
            intel-microcode
            intel-fsp
            ;
        };
        t440p = pkgs.callPackage ./coreboot {
          board = "t440p";
          inherit (inputs)
            coreboot
            edk2-platforms
            edk2-mrchromebox
            intel-microcode
            intel-fsp
            ;
        };
      };
    };
}
