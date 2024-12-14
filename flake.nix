{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=refs/heads/nixpkgs-unstable";
    coreboot = {
      url = "git+https://review.coreboot.org/coreboot.git?ref=refs/heads/main&submodules=1";
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
    edk2-platforms = {
      url = "github:tianocore/edk2-platforms";
      flake = false;
    };
    edk2-mrchromebox = {
      url = "git+https://github.com/MrChromebox/edk2?ref=refs/heads/uefipayload_2408&submodules=1";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
    in
    {
      formatter."x86_64-linux" = pkgs.nixfmt-rfc-style;
      packages."x86_64-linux" = {
        vp4670 = pkgs.callPackage ./coreboot {
          board = "vp4670";
          inherit (inputs)
            coreboot
            intel-microcode
            intel-fsp
            edk2-platforms
            edk2-mrchromebox
            ;
        };
      };
    };
}
