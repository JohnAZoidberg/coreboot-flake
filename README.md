# coreboot-flake

Build coreboot via a nix flake

# how-to flash

**vp4670**
```sh
flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=49000 -c "MX25L12833F/MX25L12835F/MX25L12845E/MX25L12865E/MX25L12873F" -w coreboot.rom
```
