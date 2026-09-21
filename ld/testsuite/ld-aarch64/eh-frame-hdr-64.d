#source: eh-frame-hdr-64.s
#ld: --eh-frame-hdr -e _start -T eh-frame-hdr-64.ld
#notarget: aarch64_be-*-*
#objdump: -s -j .eh_frame_hdr
#...
Contents of section .eh_frame_hdr:
 10000 011c033c 1c000000 00000000 01000000  .*
 10010 0000ffff 00000000 38000000 00000000  .*
