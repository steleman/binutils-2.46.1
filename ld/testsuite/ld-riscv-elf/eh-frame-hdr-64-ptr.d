#name: 64-bit .eh_frame_hdr eh_frame_ptr
#source: eh-frame-hdr-64.s
#as: -march=rv64i -mabi=lp64
#ld: -melf64lriscv --eh-frame-hdr -e _start -T eh-frame-hdr-64-ptr.ld
#objdump: -s -j .eh_frame_hdr

#...
Contents of section .eh_frame_hdr:
 10000 011c033c 0400ffff 00000000 01000000  .*
 10010 0000ffff 00000000 2000ffff 00000000  .*
