# Protectli Vault Pro VP4670

https://eu.protectli.com/product/vp4670/

## Flashing

- internally:
```sh
flashrom -p internal -w coreboot-vp4670.rom
```

- via a raspberry pi 4:
```sh
flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=49000 -c "MX25L12833F/MX25L12835F/MX25L12845E/MX25L12865E/MX25L12873F" -w coreboot-vp4670.rom
```

- by taking out the socketed BIOS chip and using a CH341A
