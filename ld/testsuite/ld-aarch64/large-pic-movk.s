# The MOV[NZ]-class GOT offset relocations select MOVZ or MOVN from the sign
# of the value, but an instruction that is already a MOVK only has its
# immediate patched.  Compilers emit sequences either as MOVZ G3 followed by
# MOVKs, or as MOVZ G0_NC followed by MOVKs ending in G3, and the placeholder
# for R_AARCH64_TLSIE_MOVW_GOTTPREL_G1 may be a MOVN.

	.text
	.global	_start
_start:
	movz	x0, #:gotoff_g0_nc:a
	movk	x0, #:gotoff_g1_nc:a
	movk	x0, #:gotoff_g2_nc:a
	movk	x0, #:gotoff_g3:a

	.reloc	., R_AARCH64_MOVW_GOTOFF_G1, a
	.inst	0x92a00001		// movn x1, #0x0, lsl #16

	.reloc	., R_AARCH64_TLSIE_MOVW_GOTTPREL_G1, tv
	.inst	0x92a00002		// movn x2, #0x0, lsl #16
	movk	x2, #:gottprel_g0_nc:tv

	.data
	.global	a
a:	.xword	0

	.section .tbss,"awT",%nobits
	.global	tv
tv:	.zero	8
