#source: large-pic-gotoff.s
#target: [check_shared_lib_support]
#ld: -shared -T relocs.ld -e0
#notarget: aarch64_be-*-*
#objdump: -d
#...
0000000000010000 <_start>:
   10000:	10000010 	adr	x16, 10000 <_start>
   10004:	d2e00011 	movz	x17, #0x0, lsl #48
   10008:	f2c00011 	movk	x17, #0x0, lsl #32
   1000c:	f2a00031 	movk	x17, #0x1, lsl #16
   10010:	f2800011 	movk	x17, #0x0
   10014:	8b110210 	add	x16, x16, x17
   10018:	d2e00000 	movz	x0, #0x0, lsl #48
   1001c:	f2c00000 	movk	x0, #0x0, lsl #32
   10020:	f2a00000 	movk	x0, #0x0, lsl #16
   10024:	f2800200 	movk	x0, #0x10
   10028:	f8606a00 	ldr	x0, \[x16, x0\]
   1002c:	d2c00001 	movz	x1, #0x0, lsl #32
   10030:	d2a00002 	movz	x2, #0x0, lsl #16
   10034:	d2800103 	mov	x3, #0x8                   	// #8
   10038:	f8636a03 	ldr	x3, \[x16, x3\]
