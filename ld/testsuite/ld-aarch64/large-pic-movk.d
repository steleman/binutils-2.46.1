#source: large-pic-movk.s
#target: [check_shared_lib_support]
#ld: -shared -T relocs.ld -e0
#notarget: aarch64_be-*-*
#objdump: -d
#...
0000000000010000 <_start>:
   10000:	d2800200 	mov	x0, #0x10                  	// #16
   10004:	f2a00000 	movk	x0, #0x0, lsl #16
   10008:	f2c00000 	movk	x0, #0x0, lsl #32
   1000c:	f2e00000 	movk	x0, #0x0, lsl #48
   10010:	d2a00001 	movz	x1, #0x0, lsl #16
   10014:	d2a00002 	movz	x2, #0x0, lsl #16
   10018:	f2800102 	movk	x2, #0x8
