{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=refs/heads/nixos-unstable-small";
    coreboot = {
      url = "git+https://github.com/coreboot/coreboot?ref=refs/tags/24.08&submodules=1";
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

  outputs = inputs: {
    formatter."x86_64-linux" = inputs.nixpkgs.legacyPackages."x86_64-linux".nixfmt-rfc-style;
    packages."x86_64-linux" =
      let
        pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
        buildCoreboot = import ./coreboot {
          inherit inputs;
          version = "24.08";
        };
      in
      {
        vp4670 = pkgs.callPackage buildCoreboot { board = "vp4670"; };
        default = inputs.self.packages."x86_64-linux".vp4670;
      };
  };
}
