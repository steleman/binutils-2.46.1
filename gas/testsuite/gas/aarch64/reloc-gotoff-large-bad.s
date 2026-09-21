// Test file for AArch64 GAS -- invalid uses of the MOVW GOT offset operators.

	.text
func:
	movk	x0, #:gotoff_g2:sym
	movk	x0, #:gotoff_g1:sym
	movk	x0, #:gotoff_g0:sym
	movz	w0, #:gotoff_g2:sym
	movz	w0, #:gotoff_g3:sym
	movk	x0, #:gottprel_g1:sym
