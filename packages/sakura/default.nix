{
  flake,
  pkgs,
  pname,
  ...
}:
pkgs.callPackage (flake.lib.mkCorebootEdk2 {
  board = pname;
  # Panther Lake selects USE_X86_64_SUPPORT, so every stage is built with the
  # x86_64-elf toolchain rather than i386-elf.
  arch = "x64";
  # The board defaults VBOOT to y.
  vboot = true;
}) { }
