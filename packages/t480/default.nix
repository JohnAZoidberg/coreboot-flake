{
  flake,
  pkgs,
  pname,
  ...
}:
pkgs.callPackage (flake.lib.mkCorebootEdk2 {
  board = pname;
}) { }
