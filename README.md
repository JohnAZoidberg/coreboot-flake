# coreboot-flake

Build coreboot via a nix flake

# how-to flash

**protectli vp4670**

internally, with `-p internal`, or externally, via a raspberry pi 4:
```sh
flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=49000 -c "MX25L12833F/MX25L12835F/MX25L12845E/MX25L12865E/MX25L12873F" -w coreboot-vp4670.rom
```
