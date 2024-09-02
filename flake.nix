{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    coreboot = {
      url = "git+https://github.com/coreboot/coreboot?ref=refs/tags/24.08&submodules=1";
      flake = false;
    };
    intel-microcode = {
      url = "github:intel/Intel-Linux-Processor-Microcode-Data-Files?rev=5278dfcf98e89098326b3eb8a85d07120a8730f8";
      flake = false;
    };
    intel-fsp = {
      url = "github:intel/FSP?rev=800c85770b458ee7f7eeb1276b46e904590d3bd7";
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

  outputs = inputs: {
    formatter."x86_64-linux" = inputs.nixpkgs.legacyPackages."x86_64-linux".nixfmt-rfc-style;
    legacyPackages."x86_64-linux" =
      let
        pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
        buildCoreboot = import ./pkgs/coreboot {
          inherit inputs;
          version = "24.08";
        };
      in
      {
        vp4670 = pkgs.callPackage buildCoreboot {
          board = "vp4670";
        };
      };
  };
}
