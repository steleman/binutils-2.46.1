# Large position-independent code model: compute the GOT base with a 64-bit
# PC-relative displacement built from R_AARCH64_MOVW_PREL_G* chunks, then
# index it with 64-bit GOT offsets built from R_AARCH64_MOVW_GOTOFF_G*.
#
# Each MOVW_PREL chunk resolves as S + A - P against its own instruction, so
# the addends compensate for the distance from the ADR.

	.text
	.global	_start
_start:
.Lpc:
	adr	x16, .Lpc
	movz	x17, #:prel_g3:_GLOBAL_OFFSET_TABLE_+4
	movk	x17, #:prel_g2_nc:_GLOBAL_OFFSET_TABLE_+8
	movk	x17, #:prel_g1_nc:_GLOBAL_OFFSET_TABLE_+12
	movk	x17, #:prel_g0_nc:_GLOBAL_OFFSET_TABLE_+16
	add	x16, x16, x17

	movz	x0, #:gotoff_g3:a
	movk	x0, #:gotoff_g2_nc:a
	movk	x0, #:gotoff_g1_nc:a
	movk	x0, #:gotoff_g0_nc:a
	ldr	x0, [x16, x0]

	movz	x1, #:gotoff_g2:b
	movz	x2, #:gotoff_g1:b
	movz	x3, #:gotoff_g0:b
	ldr	x3, [x16, x3]

	.data
	.global	a, b
a:	.xword	0
b:	.xword	0
