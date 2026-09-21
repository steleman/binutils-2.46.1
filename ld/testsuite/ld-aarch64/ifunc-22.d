#source: ifunc-22.s
#objdump: -s -j .got
#ld: -static
#target: aarch64*-*-*

# Ensure GOT is populated correctly in static link

.*:     file format elf64-(little|big)aarch64

Contents of section \.got:
#pass
