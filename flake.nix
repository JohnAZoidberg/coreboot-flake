{
  inputs = {
    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    coreboot = {
      url = "git+https://review.coreboot.org/coreboot.git?submodules=1";
      flake = false;
    };
    edk2-platforms = {
      url = "github:tianocore/edk2-platforms";
      flake = false;
    };
    edk2-mrchromebox = {
      url = "git+https://github.com/MrChromebox/edk2?ref=refs/heads/uefipayload_2502&submodules=1";
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

  outputs = inputs: inputs.blueprint { inherit inputs; };
}
