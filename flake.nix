{
  inputs = {
    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    coreboot = {
      url = "git+https://review.coreboot.org/coreboot.git?submodules=1&ref=refs/tags/26.09";
      flake = false;
    };
    edk2-platforms = {
      url = "github:tianocore/edk2-platforms";
      flake = false;
    };
    edk2-mrchromebox = {
      url = "git+https://github.com/MrChromebox/edk2?submodules=1&ref=refs/tags/26.09.1";
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
    nixpkgs.url = "github:matdibu/nixpkgs?ref=refs/heads/coreboot-toolchain-26.09";
  };

  outputs =
    inputs:
    inputs.blueprint {
      inherit inputs;
      systems = [ "x86_64-linux" ];
    };
}
