# Package directory structure

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

- `blobs/`

- `cbfs/`: files to be added into the CBFS post-build

- `patches/`
