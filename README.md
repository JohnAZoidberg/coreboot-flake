# coreboot-flake

Build coreboot+edk2 via a nix flake

## Building

```sh
nix build .#<board>
```

For possible values of `<board>`, see `./packages/`
