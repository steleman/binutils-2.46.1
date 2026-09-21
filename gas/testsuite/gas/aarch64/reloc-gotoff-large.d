#as: -mabi=lp64
#objdump: -dr
# This test is only valid on ELF based ports.
#notarget: *-*-*coff *-*-pe *-*-wince *-*-*aout* *-*-netbsd

.*:     file format .*

Disassembly of section \.text:

0000000000000000 <func>:
   0:	d2e00000 	movz	x0, #0x0, lsl #48
			0: R_AARCH64_MOVW_GOTOFF_G3	sym
   4:	f2c00000 	movk	x0, #0x0, lsl #32
			4: R_AARCH64_MOVW_GOTOFF_G2_NC	sym
   8:	f2a00000 	movk	x0, #0x0, lsl #16
			8: R_AARCH64_MOVW_GOTOFF_G1_NC	sym
   c:	f2800000 	movk	x0, #0x0
			c: R_AARCH64_MOVW_GOTOFF_G0_NC	sym
  10:	d2c00001 	movz	x1, #0x0, lsl #32
			10: R_AARCH64_MOVW_GOTOFF_G2	sym
  14:	d2a00002 	movz	x2, #0x0, lsl #16
			14: R_AARCH64_MOVW_GOTOFF_G1	sym
  18:	d2800003 	mov	x3, #0x0                   	// #0
			18: R_AARCH64_MOVW_GOTOFF_G0	sym
  1c:	92800004 	mov	x4, #0xffffffffffffffff    	// #-1
			1c: R_AARCH64_MOVW_GOTOFF_G0	sym
  20:	d2800005 	mov	x5, #0x0                   	// #0
			20: R_AARCH64_MOVW_GOTOFF_G0_NC	sym
  24:	f2a00005 	movk	x5, #0x0, lsl #16
			24: R_AARCH64_MOVW_GOTOFF_G1_NC	sym
  28:	f2c00005 	movk	x5, #0x0, lsl #32
			28: R_AARCH64_MOVW_GOTOFF_G2_NC	sym
  2c:	f2e00005 	movk	x5, #0x0, lsl #48
			2c: R_AARCH64_MOVW_GOTOFF_G3	sym
