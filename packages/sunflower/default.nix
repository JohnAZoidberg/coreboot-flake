{
  flake,
  pkgs,
  pname,
  ...
}:
pkgs.callPackage (flake.lib.mkCorebootEdk2 {
  board = pname;
  # The board defaults VBOOT to y.
  vboot = true;
}) { }
