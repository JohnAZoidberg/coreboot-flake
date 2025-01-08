# Package directory structure

Each directory corresponds to a coreboot rom, and is composed of:

- `default.nix`: package derivation, usually defined as:
  ```nix
  {
    flake,
    pkgs,
    pname,
    ...
  }:
  pkgs.callPackage (flake.lib.mkCorebootEdk2 {
    board = pname;
  }) { }
  ```

- `defconfig`: coreboot defconfig

- `blobs/` (optional)

- `cbfs/` (optional): files to be added into the CBFS post-build

- `patches/` (optional)
